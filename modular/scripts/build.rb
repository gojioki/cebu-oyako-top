#!/usr/bin/env ruby
# frozen_string_literal: true

require "base64"
require "digest"
require "fileutils"
require "pathname"

ROOT = File.expand_path("../..", __dir__)
MODULAR = File.join(ROOT, "modular")
CSS_FILE = File.join(MODULAR, "css", "site.css")
SECTIONS_DIR = File.join(MODULAR, "sections")
PREVIEW_DIR = File.join(MODULAR, "preview")
DOWNLOADS_DIR = File.join(ROOT, "downloads")
VERSION = File.read(File.join(MODULAR, "VERSION.txt")).strip
raise "VERSION.txt must be verNN or verNN-N" unless VERSION.match?(/\Aver\d+(?:-\d+)?\z/)

SECTION_FILES = Dir[File.join(SECTIONS_DIR, "*.html")].sort

def mime_type(path)
  case File.extname(path).downcase
  when ".png" then "image/png"
  when ".jpg", ".jpeg" then "image/jpeg"
  when ".webp" then "image/webp"
  else
    raise "Unsupported image type: #{path}"
  end
end

def replace_assets(html, mode:, output_dir:)
  html.gsub(/\{\{asset:([^}]+)\}\}/) do
    relative_asset = Regexp.last_match(1)
    absolute_asset = File.join(ROOT, relative_asset)
    raise "Missing asset: #{absolute_asset}" unless File.file?(absolute_asset)

    if mode == :embed
      encoded = Base64.strict_encode64(File.binread(absolute_asset))
      "data:#{mime_type(absolute_asset)};base64,#{encoded}"
    else
      Pathname.new(absolute_asset).relative_path_from(Pathname.new(output_dir)).to_s
    end
  end
end

def html_document(title:, css:, body:, external_css: nil, fullbleed: false)
  css_tag = if external_css
              %(<link rel="stylesheet" href="#{external_css}">)
            else
              "<style>\n#{css}\n</style>"
            end

  page_class = fullbleed ? "btv3-page btv3-page--fullbleed" : "btv3-page"

  <<~HTML
    <!doctype html>
    <html lang="ja">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>#{title}</title>
      #{css_tag}
    </head>
    <body>
    <div class="#{page_class}">
    #{body}
    </div>
    </body>
    </html>
  HTML
end

FileUtils.mkdir_p(PREVIEW_DIR)
FileUtils.mkdir_p(DOWNLOADS_DIR)

css = File.read(CSS_FILE)
css_cache_key = Digest::SHA256.hexdigest(css)[0, 12]
header = File.read(File.join(SECTIONS_DIR, "00_header.html"))
content_sections = SECTION_FILES.reject { |path| File.basename(path) == "00_header.html" }

# FV専用：ヘッダー＋FV＋信頼4カード＋母子留学メッセージだけ。
fv_source = header + "\n" + File.read(File.join(SECTIONS_DIR, "01_fv_trust_mother.html"))
fv_body = replace_assets(fv_source, mode: :local, output_dir: PREVIEW_DIR)
fv_css_path = "#{Pathname.new(CSS_FILE).relative_path_from(Pathname.new(PREVIEW_DIR))}?v=#{css_cache_key}"
fv_preview = html_document(
  title: "FV専用プレビュー｜ぶっ飛びセブ島親子留学",
  css: "",
  body: fv_body,
  external_css: fv_css_path
)
fv_preview_name = "#{VERSION}_FV専用プレビュー.html"
File.write(File.join(PREVIEW_DIR, fv_preview_name), fv_preview)

# 全体確認用：画像はローカル参照のため軽量。
full_source = header + "\n" + content_sections.map { |path| File.read(path) }.join("\n")
full_local_body = replace_assets(full_source, mode: :local, output_dir: PREVIEW_DIR)
full_local = html_document(
  title: "全体軽量プレビュー｜ぶっ飛びセブ島親子留学",
  css: "",
  body: full_local_body,
  external_css: fv_css_path
)
full_preview_name = "#{VERSION}_全体軽量プレビュー.html"
File.write(File.join(PREVIEW_DIR, full_preview_name), full_local)

# GitHub Pages 公開用：ルート index.html。
# CSS・画像はリポジトリ内をルート相対で参照するため軽量（追跡済みアセットを配信）。
index_body = replace_assets(full_source, mode: :local, output_dir: ROOT)
index_css_path = "#{Pathname.new(CSS_FILE).relative_path_from(Pathname.new(ROOT))}?v=#{css_cache_key}"
index_html = html_document(
  title: "ぶっ飛びセブ島親子留学｜PC版デザインプレビュー",
  css: "",
  body: index_body,
  external_css: index_css_path,
  fullbleed: true
)
File.write(File.join(ROOT, "index.html"), index_html)

# 外部持ち出し用：最後だけCSS・画像をすべて埋め込む。
standalone_body = replace_assets(full_source, mode: :embed, output_dir: DOWNLOADS_DIR)
standalone = html_document(
  title: "ぶっ飛びセブ島親子留学｜PC版デザインプレビュー",
  css: css,
  body: standalone_body,
  fullbleed: true
)
standalone_name = "#{VERSION}_ぶっ飛びセブ島親子留学_TOP_PC_統合版.html"
File.write(File.join(DOWNLOADS_DIR, standalone_name), standalone)

puts "Built:"
puts "- index.html (GitHub Pages 公開用)"
puts "- modular/preview/#{fv_preview_name}"
puts "- modular/preview/#{full_preview_name}"
puts "- downloads/#{standalone_name}"
