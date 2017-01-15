# -*- coding: utf-8 -*-

require("pathname")
require("yaml")
require("seven_zip_ruby")
require("bundler")
require("uri")
require("ruby_installer_manager/downloader")
require("ruby_installer_manager/ruby_manager")
require("ruby_installer_manager/devkit_manager")

module RubyInstallerManager
  class AutoManager
    FILE_LIST_URL = "https://raw.githubusercontent.com/masamitsu-murase/ruby_installer_manager/master/release/file_list.yml"

    extend HttpDownload

    def self.create(tmp_dir, file_list_url=FILE_LIST_URL, force: false, proxy_addr: nil, proxy_port: 80, ca_file: Downloader::CA_FILE)
      data = YAML.load(http_get_data(URI(file_list_url), Downloader::REDIRECTION_LIMIT, proxy_addr: proxy_addr, proxy_port: proxy_port, ca_file: ca_file))
      self.new(data, tmp_dir, force: force, proxy_addr: proxy_addr, proxy_port: proxy_port, ca_file: ca_file)
    end

    def initialize(data, tmp_dir, force: false, proxy_addr: nil, proxy_port: 80, ca_file: Downloader::CA_FILE)
      @data = data
      @tmp_dir = Pathname(tmp_dir)
      @proxy_addr = proxy_addr
      @proxy_port = proxy_port
      @ca_file = ca_file

      @tmp_dir.mkpath unless @tmp_dir.exist?

      @rubies = {}
      @data["ruby"].each do |name, info|
        dir = @tmp_dir + name
        cache_file_path = @tmp_dir + "#{name}.7z"
        rm = RubyInstallerManager::RubyManager.new(name, dir, info["url"], cache_file_path, force: force, proxy_addr: @proxy_addr, proxy_port: @proxy_port)
        @rubies[name] = rm
      end

      @devkits = {}
      @data["devkit"].each do |name, info|
        dir = @tmp_dir + name
        cache_file_path = @tmp_dir + "#{name}.7z"
        dm = RubyInstallerManager::DevkitManager.new(name, dir, info["url"], cache_file_path, force: force, proxy_addr: @proxy_addr, proxy_port: @proxy_port)
        @devkits[name] = dm
      end
    end

    def ruby_list
      @data["ruby"].keys
    end

    def ruby_manager(name)
      rm = @rubies[name]
      raise "#{name} not found" unless rm
      rm
    end

    def devkit_manager(name)
      dm = @devkits[name]
      raise "#{name} not found" unless dm
      dm
    end

    def devkit_for_ruby(ruby)
      devkit_name = @data["ruby"][ruby.name]["devkit"]
      return devkit_manager(devkit_name)
    end

    def rubies_for_devkit(devkit)
      ruby_name_list = @data["ruby"].select{ |name, info| info["devkit"] == devkit.name }.map{ |n, i| n }
      return ruby_name_list.map{ |name| ruby_manager(name) }
    end
  end
end

