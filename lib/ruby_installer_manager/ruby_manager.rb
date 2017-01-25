# -*- coding: utf-8 -*-

require("pathname")
require("yaml")
require("seven_zip_ruby")
require("bundler")
require("ruby_installer_manager/downloader")
require("tempfile")

module RubyInstallerManager
  class RubyManager < Downloader
    def initialize(name, dir, url, cache_file_path,
        force: false, proxy_addr: nil, proxy_port: 80, ca_file: Downloader::CA_FILE)
      super(url, cache_file_path, proxy_addr: proxy_addr, proxy_port: proxy_port, ca_file: ca_file)
      @name = name
      @dir = Pathname(dir).expand_path
      @force = force
    end
    attr_reader :name, :dir, :url

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
      Dir.chdir(dir) do
        dirs = Dir.glob("*").to_a
        raise "Too many directories" unless dirs.size == 1
        FileUtils.mv(Dir.glob(dirs[0] + "/*").to_a, ".")
        FileUtils.rmdir(dirs[0])
      end
    end

    def run_with_devkit(command, devkit, opt={})
      ruby_env do
        Tempfile.create([ "ruby_manager", ".bat" ], Dir.pwd) do |file|
          devkit_path = (devkit.dir + "devkitvars.bat").to_s.gsub("/"){ "\\" }
          file.puts "@echo off"
          file.puts("call \"#{devkit_path}\"")
          file.puts command
          file.close

          return system(file.path.to_s.gsub("/"){ "\\" }, opt)
        end
      end
    end

    def ruby_env(&block)
      Bundler.with_clean_env do
        old_path = ENV["PATH"]
        begin
          ENV["PATH"] = @dir.to_s.gsub("/"){ "\\" } + "\\bin;" + ENV["PATH"]
          block.call
        ensure
          ENV["PATH"] = old_path
        end
      end
    end

    def update_rubygems
      ruby_env do
        ret = system("gem update --system -N -q", err: :out, out: File::NULL)

        # http://guides.rubygems.org/ssl-certificate-update/
        ssl_cert_path = File.join(@dir.to_s, "lib", "ruby", "*", "rubygems", "ssl_certs")
        file = Pathname(Dir.glob(ssl_cert_path).to_a.first) + GLOBAL_SIGN_ROOT_CA_FILENAME
        if !ret && !(file.file?)
          File.open(file, "w") do |f|
            f.write(GLOBAL_SIGN_ROOT_CA_PEM)
          end
          puts "Retry to update rubygems..."
          ret = system("gem update --system -N -q", err: :out, out: File::NULL)
        end

        raise "Fail to update gem" unless ret
      end
    end

    def install_gem(gem, version: nil, platform: nil)
      ruby_env do
        str = "#{gem}"
        str += " --version \"#{version}\"" if version
        str += " --platform #{platform}" if platform
        system("gem install #{str} -N -q", err: :out, out: File::NULL)
      end
    end

    # https://raw.githubusercontent.com/rubygems/rubygems/master/lib/rubygems/ssl_certs/index.rubygems.org/GlobalSignRootCA.pem
    GLOBAL_SIGN_ROOT_CA_FILENAME = "GlobalSignRootCA.pem"
    GLOBAL_SIGN_ROOT_CA_PEM = <<'EOS'
-----BEGIN CERTIFICATE-----
MIIDdTCCAl2gAwIBAgILBAAAAAABFUtaw5QwDQYJKoZIhvcNAQEFBQAwVzELMAkG
A1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNVBAsTB1Jv
b3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw05ODA5MDExMjAw
MDBaFw0yODAxMjgxMjAwMDBaMFcxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9i
YWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290IENBMRswGQYDVQQDExJHbG9iYWxT
aWduIFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDaDuaZ
jc6j40+Kfvvxi4Mla+pIH/EqsLmVEQS98GPR4mdmzxzdzxtIK+6NiY6arymAZavp
xy0Sy6scTHAHoT0KMM0VjU/43dSMUBUc71DuxC73/OlS8pF94G3VNTCOXkNz8kHp
1Wrjsok6Vjk4bwY8iGlbKk3Fp1S4bInMm/k8yuX9ifUSPJJ4ltbcdG6TRGHRjcdG
snUOhugZitVtbNV4FpWi6cgKOOvyJBNPc1STE4U6G7weNLWLBYy5d4ux2x8gkasJ
U26Qzns3dLlwR5EiUWMWea6xrkEmCMgZK9FGqkjWZCrXgzT/LCrBbBlDSgeF59N8
9iFo7+ryUp9/k5DPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8E
BTADAQH/MB0GA1UdDgQWBBRge2YaRQ2XyolQL30EzTSo//z9SzANBgkqhkiG9w0B
AQUFAAOCAQEA1nPnfE920I2/7LqivjTFKDK1fPxsnCwrvQmeU79rXqoRSLblCKOz
yj1hTdNGCbM+w6DjY1Ub8rrvrTnhQ7k4o+YviiY776BQVvnGCv04zcQLcFGUl5gE
38NflNUVyRRBnMRddWQVDf9VMOyGj/8N7yy5Y0b2qvzfvGn9LhJIZJrglfCm7ymP
AbEVtQwdpf5pLGkkeB6zpxxxYu7KyJesF12KwvhHhm4qxFYxldBniYUr+WymXUad
DKqC5JlR3XC321Y9YeRq4VzW9v493kHMB65jUr9TU/Qr6cf9tveCX4XSQRjbgbME
HMUfpIBvFSDJ3gyICh3WZlXi/EjJKSZp4A==
-----END CERTIFICATE-----
EOS

  end
end

