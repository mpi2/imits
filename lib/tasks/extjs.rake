require 'fileutils'

namespace :extjs do
  task :config => [:environment] do
    if ! Object.constants.include?(:EXTJS_CONFIG)
      ::EXTJS_CONFIG = YAML.load_file(Rails.root + 'config/extjs.yml')
    end
  end

  task :download => [:config] do
    file = Rails.root + "tmp/#{EXTJS_CONFIG['version']}.zip"
    if ! File.file?(file)
      if ! system("cd '#{Rails.root}/tmp' && wget #{EXTJS_CONFIG['cdn_host']}#{EXTJS_CONFIG['version']}.zip")
        raise "Could not download ExtJS version '#{EXTJS_CONFIG['version']}' - check your internet settings and try again (this step is only required once)"
      end
    end
  end

  task :unpack => [:config] do
    file = Rails.root + "tmp/#{EXTJS_CONFIG['version']}.zip"
    if ! File.directory?(Rails.root + "tmp/#{EXTJS_CONFIG['version']}")
      if ! system("cd #{Rails.root}/tmp && unzip -q -o #{file}")
        raise "unzip failed!"
      end
    end
  end

  desc "Install ExtJS version configured in config/extjs.yml"
  task :install => [:config] do
    files_list = EXTJS_CONFIG['files']
    extjs_dir = Rails.root + "tmp/#{EXTJS_CONFIG['version']}"
    public_extjs_dir = Rails.root + 'public/extjs'

    if File.exist?(public_extjs_dir) then FileUtils.rm_r(public_extjs_dir) end
    FileUtils.mkdir public_extjs_dir

    files_list.each do |file|
      file_dir = File.dirname(public_extjs_dir + file)
      if ! File.directory?(file_dir)
        FileUtils.mkdir_p file_dir
      end
      FileUtils.cp_r extjs_dir + file, public_extjs_dir + file
    end
    puts "public/extjs re-created; please check in all changes to git if there are any ('git add -u public/extjs ; git add public/extjs')"
  end
end
