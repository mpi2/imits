require 'fileutils'

EXTJS_VERSION='3.3.1'

namespace :extjs do
  desc "Install extjs #{EXTJS_VERSION} as public/extjs for use by Netzke"
  task :install do

    if ! File.directory?(Rails.root + "public/ext-#{EXTJS_VERSION}")
      if ! File.file?(Rails.root + "tmp/ext-#{EXTJS_VERSION}.zip")
        if ! system("cd #{Rails.root}/tmp && wget http://extjs.cachefly.net/ext-#{EXTJS_VERSION}.zip")
          raise "wget failed!"
        end
      end

      if ! system("cd #{Rails.root}/public && unzip ../tmp/ext-#{EXTJS_VERSION}.zip")
        raise "unzip failed!"
      end
    end

    FileUtils.ln_sf "ext-#{EXTJS_VERSION}", Rails.root + 'public/extjs'
  end
end
