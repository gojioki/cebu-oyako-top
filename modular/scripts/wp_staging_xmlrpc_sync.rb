#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"
require "optparse"
require "time"
require "uri"
require "xmlrpc/client"

DEFAULT_BASE_URL = "https://stg.cebu-oyako.com"
DEFAULT_PAGE_ID = 411
DEFAULT_BASIC_KEYCHAIN_SERVICE = "cebu-oyako-stg-basic"
DEFAULT_WP_KEYCHAIN_SERVICE = "cebu-oyako-stg-wp-xmlrpc"
BACKUP_ROOT = File.expand_path("../../.wp-backups/staging", __dir__)

def keychain_password(username, service, label)
  stdout, stderr, status = Open3.capture3(
    "security", "find-generic-password", "-w", "-a", username, "-s", service
  )
  return stdout.strip if status.success? && !stdout.strip.empty?

  abort <<~MSG
    #{label} password was not found in macOS Keychain.
    Register it once with this command (the password is entered interactively):

      security add-generic-password -U -a '#{username}' -s '#{service}' -w

    #{stderr.strip}
  MSG
end

def keychain_account(service, label)
  stdout, stderr, status = Open3.capture3(
    "security", "find-generic-password", "-s", service
  )
  details = stdout + stderr
  account = details[/"acct"<blob>="([^"]+)"/, 1]
  return account if status.success? && account && !account.empty?

  abort <<~MSG
    #{label} account was not found in macOS Keychain.
    Register the credential once before using this script.

    #{stderr.strip}
  MSG
end

def keychain_credential(service, label, username_override = nil)
  username = username_override.to_s.strip
  username = keychain_account(service, label) if username.empty?
  [username, keychain_password(username, service, label)]
end

class StagingXmlRpcClient
  def initialize(base_url:, basic_username:, basic_password:, wp_username:, wp_password:)
    uri = URI.parse(base_url.sub(%r{/+\z}, "") + "/xmlrpc.php")
    abort "Staging XML-RPC requires HTTPS." unless uri.scheme == "https"

    @wp_username = wp_username
    @wp_password = wp_password
    @client = XMLRPC::Client.new2(uri.to_s)
    @client.user = basic_username
    @client.password = basic_password
    @client.timeout = 60
  end

  def profile
    call("wp.getProfile", 0, @wp_username, @wp_password)
  end

  def post(page_id)
    call(
      "wp.getPost",
      0,
      @wp_username,
      @wp_password,
      page_id,
      %w[post_id post_title post_content post_status post_modified]
    )
  end

  def update_content(page_id, content)
    call(
      "wp.editPost",
      0,
      @wp_username,
      @wp_password,
      page_id,
      { "post_content" => content }
    )
  end

  private

  def call(method, *args)
    @client.call(method, *args)
  rescue XMLRPC::FaultException => e
    abort "WordPress XML-RPC error #{e.faultCode}: #{e.faultString}"
  rescue StandardError => e
    abort "Staging API connection failed: #{e.class}: #{e.message}"
  end
end

def backup_page(page, page_id)
  timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
  directory = File.join(BACKUP_ROOT, "page-#{page_id}", timestamp)
  FileUtils.mkdir_p(directory)
  File.write(File.join(directory, "page.json"), JSON.pretty_generate(page))
  File.write(File.join(directory, "content.html"), page.fetch("post_content", ""))
  directory
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
  base_url: ENV.fetch("STG_WP_BASE_URL", DEFAULT_BASE_URL),
  page_id: Integer(ENV.fetch("STG_WP_PAGE_ID", DEFAULT_PAGE_ID.to_s)),
  basic_keychain_service: ENV.fetch("STG_BASIC_KEYCHAIN_SERVICE", DEFAULT_BASIC_KEYCHAIN_SERVICE),
  wp_keychain_service: ENV.fetch("STG_WP_KEYCHAIN_SERVICE", DEFAULT_WP_KEYCHAIN_SERVICE),
  max_diff_lines: 120,
  yes: false
}

parser = OptionParser.new do |opts|
  opts.banner = <<~BANNER
    Usage:
      ruby modular/scripts/wp_staging_xmlrpc_sync.rb check
      ruby modular/scripts/wp_staging_xmlrpc_sync.rb backup
      ruby modular/scripts/wp_staging_xmlrpc_sync.rb plan CONTENT_FILE
      ruby modular/scripts/wp_staging_xmlrpc_sync.rb publish CONTENT_FILE --yes

    User names are read automatically from macOS Keychain. STG_BASIC_USERNAME and
    STG_WP_USERNAME remain available as optional overrides.
  BANNER
  opts.on("--base-url URL", "Staging WordPress base URL") { |value| options[:base_url] = value }
  opts.on("--page-id ID", Integer, "WordPress page ID") { |value| options[:page_id] = value }
  opts.on("--basic-keychain-service NAME", "Basic Auth Keychain service") { |value| options[:basic_keychain_service] = value }
  opts.on("--wp-keychain-service NAME", "WordPress Keychain service") { |value| options[:wp_keychain_service] = value }
  opts.on("--max-diff-lines N", Integer, "Lines of diff printed to terminal") { |value| options[:max_diff_lines] = value }
  opts.on("--yes", "Required for an update") { options[:yes] = true }
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
abort "Refusing a non-staging host: #{base_uri.host}" unless base_uri.host&.start_with?("stg.")

basic_username, basic_password = keychain_credential(
  options[:basic_keychain_service],
  "Staging Basic Auth",
  ENV["STG_BASIC_USERNAME"]
)
wp_username, wp_password = keychain_credential(
  options[:wp_keychain_service],
  "Staging WordPress editor",
  ENV["STG_WP_USERNAME"]
)

client = StagingXmlRpcClient.new(
  base_url: options[:base_url],
  basic_username: basic_username,
  basic_password: basic_password,
  wp_username: wp_username,
  wp_password: wp_password
)

if command == "check"
  profile = client.profile
  page = client.post(options[:page_id])
  puts "Staging API authentication: OK"
  puts "User: #{profile["display_name"]} (#{profile["username"]})"
  puts "Page: #{page["post_title"]} (ID #{page["post_id"]})"
  puts "Status: #{page["post_status"]}"
  puts "Modified: #{page["post_modified"]}"
  exit
end

page = client.post(options[:page_id])
backup_dir = backup_page(page, options[:page_id])
puts "Backup: #{backup_dir}"

if command == "backup"
  puts "Backup completed without changing staging WordPress."
  exit
end

abort "Specify an existing CONTENT_FILE." unless content_file && File.file?(content_file)
desired = File.read(content_file)
current = page.fetch("post_content", "")
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
  puts "No changes detected. Staging WordPress was not updated."
  exit
end

if command == "plan"
  puts "Plan completed without changing staging WordPress."
  exit
end

abort "Staging update refused. Re-run with --yes after reviewing the diff." unless options[:yes]

result = client.update_content(options[:page_id], desired)
abort "WordPress did not confirm the update." unless result

verified_page = client.post(options[:page_id])
verified = verified_page.fetch("post_content", "")
unless verified == desired
  abort <<~MSG
    WordPress responded successfully, but the stored HTML differs from the requested HTML.
    The pre-update backup is here: #{backup_dir}
  MSG
end

puts "Staging WordPress update: OK"
puts "Stored HTML verification: OK"
puts "Status: #{verified_page["post_status"]}"
puts "Modified: #{verified_page["post_modified"]}"
