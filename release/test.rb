
require("yaml")

require("ruby_installer_manager")
require("pathname")
require("uri")


p RubyInstallerManager::AutoManager.create


obj = YAML.load_file("release/file_list.yml")

base_dir = Pathname(__dir__).parent + "tmp"

devkit_list = obj["devkit"].map do |k,v|
  path = base_dir + k
  cache_file = base_dir + (k + ".7z")
  [ k, v, RubyInstallerManager::DevkitManager.new(path, v["url"], cache_file) ]
end
devkit_list.map(&:last).each(&:prepare)

ruby_list = obj["ruby"].map do |k,v|
  path = base_dir + k
  cache_file = base_dir + (k + ".7z")
  [ k, v, RubyInstallerManager::RubyManager.new(path, v["url"], cache_file) ]
end

ruby_list.map(&:last).each(&:prepare)

devkit_list.each do |item|
  name = item[0]
  ruby = ruby_list.select{ |i| i[1]["devkit"] == name }
  item.last.install(ruby.map(&:last).map(&:dir))
end

