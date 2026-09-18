#!/usr/bin/env ruby
# frozen_string_literal: true

require "base64"
require "digest"
require "fileutils"
require "json"
require "net/http"
require "open3"
require "optparse"
require "time"
require "uri"

DEFAULT_BASE_URL = "https://cebu-oyako.com"
DEFAULT_PAGE_ID = 411
DEFAULT_KEYCHAIN_SERVICE = "cebu-oyako-wp-rest"
BACKUP_ROOT = File.expand_path("../../.wp-backups", __dir__)

class WordPressRestClient
  def initialize(base_url:, username:, password:)
    @base_url = base_url.sub(%r{/+\z}, "")
    @authorization = "Basic #{Base64.strict_encode64("#{username}:#{password}")}"
  end

  def get(path)
    request(Net::HTTP::Get.new(uri_for(path)))
  end

  def post(path, body)
    req = Net::HTTP::Post.new(uri_for(path))
    req["Content-Type"] = "application/json; charset=utf-8"
    req.body = JSON.generate(body)
    request(req)
  end

  private

  def uri_for(path)
    URI.join("#{@base_url}/", path.sub(%r{\A/+}, ""))
  end

  def request(req)
    req["Authorization"] = @authorization
    req["Accept"] = "application/json"
    req["User-Agent"] = "cebu-oyako-top-wp-rest-sync/1.0"

    uri = req.uri
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: 60) do |http|
      http.request(req)
    end

    unless response.is_a?(Net::HTTPSuccess)
      abort "WordPress API error: HTTP #{response.code}\n#{response.body.to_s[0, 1_000]}"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    abort "WordPress API returned invalid JSON: #{e.message}"
  end
end

def keychain_password(username, service)
  env_password = ENV["WP_APP_PASSWORD"]
  return env_password unless env_password.to_s.empty?

  stdout, stderr, status = Open3.capture3(
    "security", "find-generic-password", "-w", "-a", username, "-s", service
  )
  return stdout.strip if status.success? && !stdout.strip.empty?

  abort <<~MSG
    Application Password was not found in macOS Keychain.
    Register it once with this command (the password is entered interactively):

      security add-generic-password -U -a '#{username}' -s '#{service}' -w

    #{stderr.strip}
  MSG
end

def keychain_account(service)
  stdout, stderr, status = Open3.capture3(
    "security", "find-generic-password", "-s", service
  )
  details = stdout + stderr
  account = details[/"acct"<blob>="([^"]+)"/, 1]
  return account if status.success? && account && !account.empty?

  abort <<~MSG
    WordPress account was not found in macOS Keychain.
    Register the credential once before using this script.

    #{stderr.strip}
  MSG
end

def page_path(page_id)
  "/wp-json/wp/v2/pages/#{page_id}?context=edit"
end

def raw_content(page)
  page.dig("content", "raw").to_s
end

def backup_page(page, page_id)
  timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
  dir = File.join(BACKUP_ROOT, "page-#{page_id}", timestamp)
  FileUtils.mkdir_p(dir)
  File.write(File.join(dir, "page.json"), JSON.pretty_generate(page))
  File.write(File.join(dir, "content.html"), raw_content(page))
  dir
end

def build_diff(current, desired, directory, max_lines)
  current_path = File.join(directory, "current.html")
  desired_path = File.join(directory, "desired.html")
  diff_path = File.join(directory, "change.diff")
  File.write(current_path, current)
  File.write(desired_path, desired)

  stdout, stderr, status = Open3.capture3("diff", "-u", current_path, desired_path)
  abort "diff failed: #{stderr}" unless [0, 1].include?(status.exitstatus)

  File.write(diff_path, stdout)
  lines = stdout.lines
  preview = lines.first(max_lines).join
  preview += "\n... diff truncated; full diff: #{diff_path}\n" if lines.length > max_lines
  [diff_path, preview, status.exitstatus == 0]
end

options = {
  base_url: ENV.fetch("WP_BASE_URL", DEFAULT_BASE_URL),
  page_id: Integer(ENV.fetch("WP_PAGE_ID", DEFAULT_PAGE_ID.to_s)),
  keychain_service: ENV.fetch("WP_KEYCHAIN_SERVICE", DEFAULT_KEYCHAIN_SERVICE),
  max_diff_lines: 120,
  yes: false
}

parser = OptionParser.new do |opts|
  opts.banner = <<~BANNER
    Usage:
      ruby modular/scripts/wp_rest_sync.rb check
      ruby modular/scripts/wp_rest_sync.rb backup
      ruby modular/scripts/wp_rest_sync.rb plan CONTENT_FILE
      ruby modular/scripts/wp_rest_sync.rb publish CONTENT_FILE --yes

    The user name is read automatically from macOS Keychain. WP_USERNAME remains
    available as an optional override.
  BANNER
  opts.on("--base-url URL", "WordPress base URL") { |v| options[:base_url] = v }
  opts.on("--page-id ID", Integer, "WordPress page ID") { |v| options[:page_id] = v }
  opts.on("--keychain-service NAME", "macOS Keychain service name") { |v| options[:keychain_service] = v }
  opts.on("--max-diff-lines N", Integer, "Lines of diff printed to terminal") { |v| options[:max_diff_lines] = v }
  opts.on("--yes", "Required for a live update") { options[:yes] = true }
  opts.on("-h", "--help", "Show this help") do
    puts opts
    exit
  end
end

parser.parse!
command = ARGV.shift
content_file = ARGV.shift
abort parser.to_s unless %w[check backup plan publish].include?(command)

base_uri = URI.parse(options[:base_url])
abort "WordPress REST API requires HTTPS." unless base_uri.scheme == "https"
abort "Refusing a non-production host: #{base_uri.host}" unless base_uri.host == "cebu-oyako.com"

username = ENV["WP_USERNAME"].to_s.strip
username = keychain_account(options[:keychain_service]) if username.empty?

password = keychain_password(username, options[:keychain_service])
client = WordPressRestClient.new(
  base_url: options[:base_url],
  username: username,
  password: password
)

if command == "check"
  user = client.get("/wp-json/wp/v2/users/me?context=edit")
  page = client.get(page_path(options[:page_id]))
  puts "Authentication: OK"
  puts "User: #{user["name"]} (ID #{user["id"]})"
  puts "Page: #{page.dig("title", "raw")} (ID #{page["id"]})"
  puts "Status: #{page["status"]}"
  puts "Modified: #{page["modified"]}"
  exit
end

page = client.get(page_path(options[:page_id]))
backup_dir = backup_page(page, options[:page_id])
puts "Backup: #{backup_dir}"

if command == "backup"
  puts "Backup completed without changing WordPress."
  exit
end

abort "Specify an existing CONTENT_FILE." unless content_file && File.file?(content_file)
desired = File.read(content_file)
current = raw_content(page)
diff_path, diff_preview, unchanged = build_diff(
  current,
  desired,
  backup_dir,
  options[:max_diff_lines]
)

puts "Current SHA256: #{Digest::SHA256.hexdigest(current)}"
puts "Desired SHA256: #{Digest::SHA256.hexdigest(desired)}"
puts "Diff: #{diff_path}"
puts diff_preview unless diff_preview.empty?

if unchanged
  puts "No changes detected. WordPress was not updated."
  exit
end

if command == "plan"
  puts "Plan completed without changing WordPress."
  exit
end

abort "Live update refused. Re-run with --yes after reviewing the diff." unless options[:yes]

client.post("/wp-json/wp/v2/pages/#{options[:page_id]}", { "content" => desired })
verified_page = client.get(page_path(options[:page_id]))
verified = raw_content(verified_page)

unless verified == desired
  abort <<~MSG
    WordPress responded successfully, but the stored HTML differs from the requested HTML.
    The pre-update backup is here: #{backup_dir}
  MSG
end

puts "WordPress update: OK"
puts "Stored HTML verification: OK"
puts "Status: #{verified_page["status"]}"
puts "Modified: #{verified_page["modified"]}"
