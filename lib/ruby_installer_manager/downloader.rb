# -*- coding: utf-8 -*-

require("pathname")
require("net/http")
require("uri")
require("openssl")

module RubyInstallerManager
  module HttpDownload
    CA_FILE = (Pathname(__dir__) + "cacert.pem").to_s

    def http_get(url, file_path, limit, proxy_addr: nil, proxy_port: 80, ca_file: CA_FILE)
      res_body = http_get_data(url, limit, proxy_addr: proxy_addr, proxy_port: proxy_port, ca_file: ca_file)

      File.open(file_path, "wb") do |file|
        file.write(res_body)
      end
    end

    def http_get_data(url, limit, proxy_addr: nil, proxy_port: 80, ca_file: CA_FILE)
      if proxy_addr
        http = Net::HTTP.new(url.host, url.port, proxy_addr, proxy_port)
      else
        http = Net::HTTP.new(url.host, url.port, nil)
      end

      if url.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.ca_file = ca_file.to_s
      end

      req = Net::HTTP::Get.new(url.request_uri)
      res = http.start do |h|
        h.request(req)
      end

      case res
      when Net::HTTPSuccess
        # OK
      when Net::HTTPRedirection
        raise "Redirect error" if limit <= 0
        return http_get_data(URI.parse(res['location']), limit - 1,
                        proxy_addr: proxy_addr, proxy_port: proxy_port, ca_file: ca_file)
      else
        raise "Invalid return value: #{res}"
      end

      return res.body
    end
  end

  class Downloader
    include HttpDownload

    REDIRECTION_LIMIT = 10

    def initialize(url, file_path, proxy_addr: nil, proxy_port: 80, ca_file: CA_FILE)
      @url = URI.parse(url)
      if file_path
        @file_path = Pathname(file_path).expand_path
      else
        @file_path = nil
      end
      @proxy_addr = proxy_addr
      @proxy_port = proxy_port
      @ca_file = ca_file
    end

    def download(url, limit=REDIRECTION_LIMIT)
      if @file_path
        http_get(url, @file_path, limit, proxy_addr: @proxy_addr, proxy_port: @proxy_port, ca_file: @ca_file)
      else
        http_get_data(url, limit, proxy_addr: @proxy_addr, proxy_port: @proxy_port, ca_file: @ca_file)
      end
    end
  end
end
