#!/usr/bin/env ruby
# frozen_string_literal: true

require "base64"
require "fileutils"
require "pathname"

ROOT = File.expand_path("../..", __dir__)
MODULAR = File.join(ROOT, "modular")
CSS_FILE = File.join(MODULAR, "css", "site.css")
SECTIONS_DIR = File.join(MODULAR, "sections")
PREVIEW_DIR = File.join(MODULAR, "preview")
DOWNLOADS_DIR = File.join(ROOT, "downloads")
VERSION = File.read(File.join(MODULAR, "VERSION.txt")).strip

def mime_type(path)
  case File.extname(path).downcase
  when ".png" then "image/png"
  when ".jpg", ".jpeg" then "image/jpeg"
  when ".webp" then "image/webp"
  else raise "Unsupported image type: #{path}"
  end
end

def replace_assets(html, root:, mode:, output_dir:)
  html.gsub(/\{\{asset:([^}]+)\}\}/) do
    asset = File.join(root, Regexp.last_match(1))
    raise "Missing asset: #{asset}" unless File.file?(asset)

    if mode == :embed
      "data:#{mime_type(asset)};base64,#{Base64.strict_encode64(File.binread(asset))}"
    else
      Pathname.new(asset).relative_path_from(Pathname.new(output_dir)).to_s
    end
  end
end

def document(title:, body:, css: nil, css_href: nil)
  style = css_href ? %(<link rel="stylesheet" href="#{css_href}">) : "<style>\n#{css}\n</style>"
  <<~HTML
    <!doctype html>
    <html lang="ja">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>#{title}</title>
      #{style}
    </head>
    <body>
      <div class="btv3-page">
    #{body}
      </div>
    </body>
    </html>
  HTML
end

FileUtils.mkdir_p(PREVIEW_DIR)
FileUtils.mkdir_p(DOWNLOADS_DIR)

# Chat B scope only: front navigation, school directory banner, and merit bar.
source = ["02_front_navigation.html", "03_merit_band.html"].map do |name|
  File.read(File.join(SECTIONS_DIR, name))
end.join("\n")

css = File.read(CSS_FILE)
local_body = replace_assets(source, root: ROOT, mode: :local, output_dir: PREVIEW_DIR)
css_href = Pathname.new(CSS_FILE).relative_path_from(Pathname.new(PREVIEW_DIR)).to_s
preview_name = "#{VERSION}_チャットB_上段ブロック軽量プレビュー.html"
File.write(
  File.join(PREVIEW_DIR, preview_name),
  document(title: "チャットB 上段ブロック｜ぶっ飛びセブ島親子留学", body: local_body, css_href: css_href)
)

embedded_body = replace_assets(source, root: ROOT, mode: :embed, output_dir: DOWNLOADS_DIR)
standalone_name = "#{VERSION}_チャットB_こんな不安から魅力バーまで_画像埋め込み版.html"
File.write(
  File.join(DOWNLOADS_DIR, standalone_name),
  document(title: "チャットB 上段ブロック｜ぶっ飛びセブ島親子留学", body: embedded_body, css: css)
)

puts "Built:"
puts "- modular/preview/#{preview_name}"
puts "- downloads/#{standalone_name}"
