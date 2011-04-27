require 'fileutils'

require File.dirname(__FILE__) + '/../../config/extjs.rb'

namespace :extjs do
  desc "Install extjs #{EXTJS_VERSION} as public/extjs for use by Netzke"
  task :install do

    if ! File.directory?(Rails.root + "public/ext-#{EXTJS_VERSION}")
      if ! File.file?(Rails.root + "tmp/ext-#{EXTJS_VERSION}.zip")
        if ! system("cd #{Rails.root}/tmp && wget #{EXTJS_DOWNLOAD_URL}")
          raise "wget failed!"
        end
      end

      if ! system("cd #{Rails.root}/public && unzip -o ../tmp/ext-#{EXTJS_VERSION}.zip")
        raise "unzip failed!"
      end
    end

    FileUtils.rm_f Rails.root + 'public/extjs'
    FileUtils.ln_sf "ext-#{EXTJS_VERSION}", Rails.root + 'public/extjs'
  end
end
