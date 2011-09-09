require 'fileutils'

require File.dirname(__FILE__) + '/../../config/extjs.rb'

namespace :extjs do
  desc "Install extjs #{EXTJS_VERSION} as public/extjs"
  task :install do

    if ! File.directory?(Rails.root + "public/#{EXTJS_BASEDIR}")
      file = "#{EXTJS_PATH}/#{EXTJS_ZIPFILE}"
      file = Rails.root + "tmp/#{EXTJS_ZIPFILE}" if ! File.file?(file)
      raise "Cannot find zip file at #{EXTJS_PATH}/#{EXTJS_ZIPFILE} or #{file}!" if ! File.file?(file)
      if ! system("cd #{Rails.root}/public && unzip -q -o #{file}")
        raise "unzip failed!"
      end
    end

    FileUtils.rm_f Rails.root + 'public/extjs'
    FileUtils.ln_sf "#{EXTJS_BASEDIR}", Rails.root + 'public/extjs'
  end
end
