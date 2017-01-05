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

    def self.create(file_list_url=FILE_LIST_URL, proxy_addr: nil, proxy_port: 80, ca_file: Downloader::CA_FILE)
      data = YAML.load(http_get_data(URI(file_list_url), Downloader::REDIRECTION_LIMIT, proxy_addr: proxy_addr, proxy_port: proxy_port, ca_file: ca_file))
      self.new(data, proxy_addr: proxy_addr, proxy_port: proxy_port, ca_file: ca_file)
    end

    def initialize(data, proxy_addr: nil, proxy_port: 80, ca_file: Downloader::CA_FILE)
      @data = data
      @proxy_addr = proxy_addr
      @proxy_port = proxy_port
      @ca_file = ca_file
    end

    def ruby_list
      @data["ruby"].keys
    end

    def ruby_manager(name, dir, cache_file_path, force: false)
      info = @data["ruby"][name]
      raise "#{name} not found" unless info
      RubyInstallerManager::RubyManager.new(dir, info["url"], cache_file_path, force: force)
    end

    def devkit_manager(name, dir, cache_file_path, force: false)
      info = @data["devkit"][name]
      raise "#{name} not found" unless info
      RubyInstallerManager::DevkitManager.new(dir, info["url"], cache_file_path, force: force)
    end

    def devkit_name_for_ruby(ruby_name)
      ruby_info = @data["ruby"][ruby_name]
      raise "#{ruby_name} not found" unless ruby_info

      ruby_info["devkit"]
    end
  end
end

