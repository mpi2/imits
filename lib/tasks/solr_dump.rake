
require "pp"
require "#{Rails.root}/script/solr_dump_restore.rb"

namespace :solr_dump do

  desc 'dump'
  task 'dump', [:source_solr_url] => :environment do |t, args|
    args.with_defaults(:source_solr_url => 'http://ikmc.vm.bytemark.co.uk:8984/solr')

    options = {
      :solr_url_dump => args[:source_solr_url],
      :dump_directory => "#{Rails.root}/tmp/solr_dump",
      :batch_size => 1000,
      :log => true,
      :cleanup => false,
      :solr_url_restore => nil,
      :dump => true,
      :restore => false
    }

    raise "#### source & destination url's cannot be the same!" if args[:source_solr_url] == args[:dest_solr_url]

    pp options

    SolrDump.new(options).run
  end

  desc 'restore'
  task 'restore', [:dest_solr_url] => :environment do |t, args|
    args.with_defaults(:dest_solr_url => 'http://htgt1.internal.sanger.ac.uk:8983/solr')

    options = {
      :solr_url_dump => nil,
      :dump_directory => "#{Rails.root}/tmp/solr_dump",
      :batch_size => 1000,
      :log => true,
      :cleanup => false,
      :solr_url_restore => args[:dest_solr_url],
      :dump => false,
      :restore => true
    }

    raise "#### source & destination url's cannot be the same!" if args[:source_solr_url] == args[:dest_solr_url]

    pp options

    SolrRestore.new(options).run
  end

end
