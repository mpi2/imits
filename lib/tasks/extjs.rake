require 'fileutils'

namespace :extjs do
  desc "Install extjs"
  task :install => [:environment] do
    extjs_version = Extjs::CONFIG['version']
    if ! File.directory?(Rails.root + "public/#{extjs_version}")
      file = Rails.root + "tmp/#{extjs_version}.zip"
      if ! File.file?(file)
        if ! system("cd '#{Rails.root}/tmp' && wget #{Extjs::CONFIG['cdn_host']}#{Extjs::CONFIG['version']}.zip")
          raise "Could not download ExtJS version '#{Extjs::CONFIG['version']}' - check your internet settings and try again (this step is only required once)"
        end
      end
      if ! system("cd #{Rails.root}/public && unzip -q -o #{file}")
        raise "unzip failed!"
      end
    end

    FileUtils.rm_f Rails.root + 'public/extjs'
    FileUtils.ln_sf "#{extjs_version}", Rails.root + 'public/extjs'
  end
end
