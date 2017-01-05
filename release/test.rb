
require("yaml")

require("ruby_installer_manager")
require("pathname")
require("uri")


base_dir = Pathname(__dir__).parent + "tmp"

am = RubyInstallerManager::AutoManager.create
p am.ruby_list


ruby_name_list = [ "ruby2.3.3", "ruby2.2.6" ]

ruby_list = ruby_name_list.map do |ruby_name|
  next am.ruby_manager(ruby_name, base_dir + ruby_name, base_dir + "#{ruby_name}.7z")
end

devkit_name_list = ruby_name_list.map{ |i| am.devkit_name_for_ruby(i) }.uniq
devkit_list = devkit_name_list.map do |devkit_name|
  next am.devkit_manager(devkit_name, base_dir + devkit_name, base_dir + "#{devkit_name}.7z")
end


#================================================================
# Prepare and install
ruby_list.zip(ruby_name_list) do |ruby, ruby_name|
  puts ruby_name
  ruby.prepare
end

devkit_list.zip(devkit_name_list) do |devkit, devkit_name|
  puts devkit_name
  devkit.prepare
end

devkit_list.zip(devkit_name_list) do |devkit, devkit_name|
  devkit.install(ruby_list.zip(ruby_name_list).select{ |i,j| am.devkit_name_for_ruby(j) == devkit_name }.map(&:first))
end

