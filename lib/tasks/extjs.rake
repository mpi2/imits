require 'fileutils'

namespace :extjs do
  desc "Install extjs"
  task :install => [:environment] do
    extjs_version = Extjs::CONFIG['version']
    if ! File.directory?(Rails.root + "public/#{extjs_version}")
      file = Rails.root + "tmp/#{extjs_version}.zip"
      raise "Cannot find zip file at #{file}" if ! File.file?(file)
      if ! system("cd #{Rails.root}/public && unzip -q -o #{file}")
        raise "unzip failed!"
      end
    end

    FileUtils.rm_f Rails.root + 'public/extjs'
    FileUtils.ln_sf "#{extjs_version}", Rails.root + 'public/extjs'
  end
end
