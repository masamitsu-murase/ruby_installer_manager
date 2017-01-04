# -*- coding: utf-8 -*-

require("pathname")
require("yaml")
require("seven_zip_ruby")
require("bundler")
require("uri")
require("ruby_installer_manager/downloader")

module RubyInstallerManager
  class AutoManager
    FILE_LIST_URL = "https://raw.githubusercontent.com/masamitsu-murase/ruby_installer_manager/master/release/file_list.yml"

    extend HttpDownload

    def self.create(file_list_url=FILE_LIST_URL, proxy_addr: nil, proxy_port: 80, ca_file: Downloader::CA_FILE)
      self.new(http_get_data(URI(file_list_url), Downloader::REDIRECTION_LIMIT, proxy_addr: proxy_addr, proxy_port: proxy_port, ca_file: ca_file))
    end

    def initialize(data)
      @data = data
    end
  end
end

