# frozen_string_literal: true

require "cgi"

modular = File.expand_path("..", __dir__)
section_name = ARGV.fetch(0, "09_cost")
output_name = ARGV.fetch(1, "ver27_09料金ブロック単体プレビュー.html")
section_path = File.join(modular, "sections", "#{section_name}.html")
css_path = File.join(modular, "css", "site.css")
output_path = File.join(modular, "preview", output_name)

section = File.read(section_path, encoding: "UTF-8")
css = File.read(css_path, encoding: "UTF-8")
title = CGI.escapeHTML("#{section_name} 単体プレビュー")

section = section.gsub(/\{\{asset:([^}]+)\}\}/) do
  asset_path = Regexp.last_match(1)
  absolute_asset = File.expand_path(asset_path, File.expand_path("../..", __dir__))
  raise "Missing asset: #{absolute_asset}" unless File.file?(absolute_asset)

  "../../#{asset_path}"
end

document = <<~HTML
  <!doctype html>
  <html lang="ja">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>#{title}</title>
    <style>#{css}</style>
  </head>
  <body>
    <div class="btv3-page">
      #{section}
    </div>
  </body>
  </html>
HTML

File.write(output_path, document, mode: "w", encoding: "UTF-8")
puts output_path
