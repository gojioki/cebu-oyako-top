#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "fileutils"
require "tmpdir"

ROOT = File.expand_path("../..", __dir__)
MODULAR = File.join(ROOT, "modular")
VERSION = File.read(File.join(MODULAR, "VERSION.txt")).strip
DATE = Date.today.strftime("%Y%m%d")
DELIVERIES = File.join(ROOT, "deliveries")
OUTPUT = File.join(DELIVERIES, "#{VERSION}_確定版_#{DATE}.zip")

raise "VERSION.txt must be verNN or verNN-N" unless VERSION.match?(/\Aver\d+(?:-\d+)?\z/)
raise "Package already exists: #{OUTPUT}" if File.exist?(OUTPUT)

FileUtils.mkdir_p(DELIVERIES)

Dir.mktmpdir("#{VERSION}-release-") do |tmp|
  package = File.join(tmp, VERSION)
  preview_dir = File.join(package, "preview")
  integrated_dir = File.join(package, "integrated")
  source_dir = File.join(package, "source")
  swell_dir = File.join(package, "swell")

  [preview_dir, integrated_dir, source_dir, swell_dir].each { |dir| FileUtils.mkdir_p(dir) }

  FileUtils.cp(File.join(ROOT, "index.html"), File.join(package, "index.html"))
  FileUtils.cp(File.join(MODULAR, "preview", "#{VERSION}_FV専用プレビュー.html"), preview_dir)
  FileUtils.cp(File.join(MODULAR, "preview", "#{VERSION}_全体軽量プレビュー.html"), preview_dir)
  FileUtils.cp(File.join(ROOT, "downloads", "#{VERSION}_ぶっ飛びセブ島親子留学_TOP_PC_統合版.html"), integrated_dir)

  FileUtils.cp_r(File.join(MODULAR, "sections"), source_dir)
  FileUtils.mkdir_p(File.join(source_dir, "css"))
  FileUtils.cp(File.join(MODULAR, "css", "site.css"), File.join(source_dir, "css"))
  FileUtils.cp_r(File.join(MODULAR, "scripts"), source_dir)
  FileUtils.cp(File.join(MODULAR, "VERSION.txt"), source_dir)

  swell_files = Dir[File.join(DELIVERIES, "#{VERSION}_SWELL試し入稿用_*")]
  raise "SWELL trial files are missing" if swell_files.empty?
  FileUtils.cp(swell_files, swell_dir)

  section_source = Dir[File.join(MODULAR, "sections", "*.html")].map { |path| File.read(path) }.join("\n")
  asset_paths = section_source.scan(/\{\{asset:([^}]+)\}\}/).flatten.uniq.sort
  asset_paths.each do |relative|
    source = File.join(ROOT, relative)
    raise "Missing asset: #{source}" unless File.file?(source)

    destination = File.join(package, relative)
    FileUtils.mkdir_p(File.dirname(destination))
    FileUtils.cp(source, destination)
  end

  readme = <<~TEXT
    #{VERSION} 確定版

    preview/     ローカル確認用HTML
    integrated/  CSS・画像埋め込み済み単体HTML
    source/      セクションHTML・CSS・生成スクリプト
    assets/      現在のトップページで使用している画像
    swell/       SWELL下書き固定ページへの試し入稿用データ

    GitHub Pages: https://gojioki.github.io/cebu-oyako-top/
  TEXT
  File.write(File.join(package, "README.txt"), readme)

  Dir.chdir(tmp) do
    ok = system("zip", "-qry", OUTPUT, VERSION)
    raise "zip command failed" unless ok
  end
end

puts OUTPUT
