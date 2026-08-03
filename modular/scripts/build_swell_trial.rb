#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"

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
source = section_files.map { |path| File.read(path) }.join("\n")
body = source.gsub(/\{\{asset:([^}]+)\}\}/) do
  relative_asset = Regexp.last_match(1)
  absolute_asset = File.join(ROOT, relative_asset)
  raise "Missing asset: #{absolute_asset}" unless File.file?(absolute_asset)

  "#{ASSET_BASE}/#{relative_asset}"
end

css = File.read(CSS_FILE)
wrapped_body = %(<div class="btv3-page">\n#{body}\n</div>\n)
inline = "<style>\n#{css}\n</style>\n#{wrapped_body}"

base = File.join(DELIVERIES_DIR, "#{VERSION}_SWELL試し入稿用")
File.write("#{base}_本文.html", wrapped_body)
File.write("#{base}_CSS.css", css)
File.write("#{base}_1ファイル.html", inline)

instructions = <<~TEXT
  #{VERSION} SWELL試し入稿手順

  1. 必ず非公開の下書き固定ページで試してください。
  2. ページは「1カラム／サイドバーなし／フルワイド」にします。
  3. 最短確認は「#{VERSION}_SWELL試し入稿用_1ファイル.html」の中身を、カスタムHTMLブロックへ貼り付けます。
  4. styleタグが保存時に除去される場合は、CSSファイルを追加CSSまたは子テーマへ入れ、本文HTMLだけを貼り付けます。
  5. SWELL標準ヘッダーと今回のヘッダーが二重になる場合は、公開せず、ページテンプレートまたは表示設定を調整します。
  6. 固定ページタイトルのH1が別に表示される場合も、重複状態を確認してから調整します。
  7. 画像は試し入稿用としてGitHub Pagesを参照しています。本番確定時はWordPress側の画像URLへ置換します。
  8. PC・タブレット・スマホ実機で確認し、問題のスクリーンショットをCodexへ共有してください。
TEXT

File.write("#{base}_手順.txt", instructions)

puts "Built SWELL trial files:"
puts "- #{base}_本文.html"
puts "- #{base}_CSS.css"
puts "- #{base}_1ファイル.html"
puts "- #{base}_手順.txt"
