require 'fileutils'

require File.dirname(__FILE__) + '/../../config/extjs.rb'

namespace :extjs do
  task :download do
    if ! File.file?(Rails.root + "tmp/#{EXTJS_ZIPFILE}")
      if ! system("cd #{Rails.root}/tmp && wget -q #{EXTJS_DOWNLOAD_URL} -O #{EXTJS_ZIPFILE}")
        raise "wget failed!"
      end
    end
  end

  desc "Install extjs #{EXTJS_VERSION} as public/extjs"
  task :install => :download do

    if ! File.directory?(Rails.root + "public/#{EXTJS_BASEDIR}")
      if ! system("cd #{Rails.root}/public && unzip -q -o ../tmp/#{EXTJS_ZIPFILE}")
        raise "unzip failed!"
      end
    end

    FileUtils.rm_f Rails.root + 'public/extjs'
    FileUtils.ln_sf "#{EXTJS_BASEDIR}", Rails.root + 'public/extjs'
  end
end
