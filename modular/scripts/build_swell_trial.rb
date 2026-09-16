#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "cgi"

ROOT = File.expand_path("../..", __dir__)
MODULAR = File.join(ROOT, "modular")
SECTIONS_DIR = File.join(MODULAR, "sections")
CSS_FILE = File.join(MODULAR, "css", "site.css")
DELIVERIES_DIR = File.join(ROOT, "deliveries")
VERSION = File.read(File.join(MODULAR, "VERSION.txt")).strip
ASSET_BASE = "https://gojioki.github.io/cebu-oyako-top"

raise "VERSION.txt must be verNN or verNN-N" unless VERSION.match?(/\Aver\d+(?:-\d+)?\z/)

FileUtils.mkdir_p(DELIVERIES_DIR)

section_files = Dir[File.join(SECTIONS_DIR, "*.html")].sort

def build_body(paths)
  source = paths.map { |path| File.read(path) }.join("\n")
  source.gsub(/\{\{asset:([^}]+)\}\}/) do
    relative_asset = Regexp.last_match(1)
    absolute_asset = File.join(ROOT, relative_asset)
    raise "Missing asset: #{absolute_asset}" unless File.file?(absolute_asset)

    "#{ASSET_BASE}/#{relative_asset}"
  end
end

css = File.read(CSS_FILE)
standard_section_files = section_files.reject { |path| File.basename(path) == "00_header.html" }
standard_body = build_body(standard_section_files)
custom_header_body = build_body(section_files)

wrapped_standard_body = %(<div class="btv3-page">\n#{standard_body}\n</div>\n)
wrapped_custom_header_body = %(<div class="btv3-page">\n#{custom_header_body}\n</div>\n)
standard_inline = "<meta charset=\"utf-8\">\n<style>\n#{css}\n</style>\n#{wrapped_standard_body}"
custom_header_inline = "<meta charset=\"utf-8\">\n<style>\n#{css}\n</style>\n#{wrapped_custom_header_body}"
gutenberg_payload = "<!-- wp:html -->\n<style>\n#{css}\n</style>\n#{wrapped_standard_body}<!-- /wp:html -->\n"
standard_gutenberg = "<meta charset=\"utf-8\">\n#{gutenberg_payload}"

base = File.join(DELIVERIES_DIR, "#{VERSION}_SWELL試し入稿用")
File.write("#{base}_本文.html", wrapped_standard_body)
File.write("#{base}_CSS.css", css)
File.write("#{base}_1ファイル.html", standard_inline)
File.write("#{base}_Gutenbergコードエディター用.html", standard_gutenberg)
File.write("#{base}_Gutenbergコードエディター用.txt", gutenberg_payload)
File.write(
  "#{base}_Gutenberg転送用.html",
  "<!doctype html><html lang=\"ja\"><head><meta charset=\"utf-8\"><title>SWELL Gutenberg transfer</title></head><body><textarea id=\"payload\">#{CGI.escapeHTML(gutenberg_payload)}</textarea></body></html>"
)
File.write("#{base}_カスタムヘッダー比較用_1ファイル.html", custom_header_inline)

instructions = <<~TEXT
  #{VERSION} SWELL試し入稿手順

  1. 必ず非公開の下書き固定ページで試してください。
  2. ページは「1カラム／サイドバーなし／フルワイド」にします。
  3. Gutenbergのコードエディターへ貼る場合は「#{VERSION}_SWELL試し入稿用_Gutenbergコードエディター用.txt」を使います。wp:htmlで囲み、WordPressの自動段落挿入を防いでいます。HTML版はブラウザ表示確認用です。
  4. ビジュアルエディターでカスタムHTMLブロックを1つ作る場合は「#{VERSION}_SWELL試し入稿用_1ファイル.html」のmetaタグを除く中身を貼ります。通常版はSWELL標準ヘッダーを使うため、00_header.htmlを除外しています。
  5. 独自ヘッダーとの比較が必要な場合だけ「#{VERSION}_SWELL試し入稿用_カスタムヘッダー比較用_1ファイル.html」を使います。公開版には両方のヘッダーを同時表示しません。
  6. styleタグが保存時に除去される場合は、CSSファイルを追加CSSまたは子テーマへ入れ、本文HTMLだけを貼り付けます。
  7. 表示中FVは画像主体で、本文内のH1は非表示の旧FV内にあります。固定ページタイトルを非表示にする場合は、公開前に検索・アクセシビリティ上有効なH1を別途1件設置します。
  8. 画像は試し入稿用としてGitHub Pagesを参照しています。本番確定時はWordPress側の画像URLへ置換します。
  9. PC・タブレット・スマホ実機で確認し、問題のスクリーンショットをCodexへ共有してください。
TEXT

File.write("#{base}_手順.txt", instructions)

puts "Built SWELL trial files:"
puts "- #{base}_本文.html"
puts "- #{base}_CSS.css"
puts "- #{base}_1ファイル.html"
puts "- #{base}_Gutenbergコードエディター用.html"
puts "- #{base}_Gutenbergコードエディター用.txt"
puts "- #{base}_Gutenberg転送用.html"
puts "- #{base}_カスタムヘッダー比較用_1ファイル.html"
puts "- #{base}_手順.txt"
