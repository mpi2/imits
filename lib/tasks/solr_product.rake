require 'pp'
require "#{Rails.root}/config/environment"
require "#{Rails.root}/script/build_product_core.rb"
#require 'zipruby'

namespace :solr_product do

  DATABASE = YAML.load_file("#{Rails.root}/config/database.yml")
  SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")

  desc 'Build the product core'
  task 'build' => [:environment] do
    BuildProductCore.new.run
  end

  desc 'Ping the solr'
  task 'index:ping' => [:environment] do
    command = 'curl -s SOLR_SUBS/admin/ping |grep -o -E "name=\"status\">([0-9]+)<"|cut -f2 -d\>|cut -f1 -d\<'.gsub(/SOLR_SUBS/, SOLR_UPDATE[Rails.env]['index_proxy']['product'])
    output = `#{command}`
    if output.to_s.length > 0 && output.to_i == 0
      puts "#### #{SOLR_UPDATE[Rails.env]['index_proxy']['allele']} up and running!".green
    elsif output.empty?
      puts "#### #{SOLR_UPDATE[Rails.env]['index_proxy']['allele']} NOT running!".red
    else
      puts "#### #{SOLR_UPDATE[Rails.env]['index_proxy']['allele']} broken!".red
    end
  end

end
