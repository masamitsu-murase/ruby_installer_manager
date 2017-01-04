# -*- coding: utf-8 -*-

require("pathname")
require("yaml")
require("rbconfig")
require("seven_zip_ruby")
require("ruby_installer_manager/downloader")

module RubyInstallerManager
  class DevkitManager < Downloader
    def initialize(dir, url, cache_file_path,
        force: false, proxy_addr: nil, proxy_port: 80, ca_file: Downloader::CA_FILE)
      super(url, cache_file_path, proxy_addr: proxy_addr, proxy_port: proxy_port, ca_file: ca_file)
      @dir = Pathname(dir).expand_path
      @force = force
    end
    attr_reader :dir, :url

    def prepare
      clear_cache if @force

      unless @file_path.exist?
        @file_path.parent.mkpath unless @file_path.parent.exist?
        download(@url)
      end

      extract(@file_path, @dir)
    end

    def clear_cache
      @file_path.rmtree if @file_path.exist?
    end

    def extract(file, dir)
      dir.rmtree if dir.exist?
      dir.mkpath

      File.open(file, "rb") do |file|
        Dir.chdir(dir) do
          SevenZipRuby::Reader.extract_all(file, ".")
        end
      end
    end

    def install(ruby_path_list, ruby_path=RbConfig::ruby)
      Dir.chdir(@dir) do
        yaml = "config.yml"
        File.open(yaml, "w") do |file|
          file.puts YAML.dump(ruby_path_list.map(&:to_s))
        end

        system("\"#{ruby_path}\" dk.rb install", err: :out, out: File::NULL)
      end
    end
  end
end
