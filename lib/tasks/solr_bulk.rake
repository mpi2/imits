
require "#{Rails.root}/script/solr_bulk/test/phenotype_attempts_test.rb"
require "#{Rails.root}/script/solr_bulk/test/mi_attempts_test.rb"
require "#{Rails.root}/script/solr_bulk/test/genes_test.rb"

namespace :solr_bulk do

  DATABASE = YAML.load_file("#{Rails.root}/config/database.yml")
  SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")
  LEGAL_TARGETS = %W{genes phenotype_attempts mi_attempts alleles all partial}

  desc 'Return details of the db solr state'
  task 'stats' => [:environment] do
    PhenotypeAttemptsTest.summary
  end

  desc 'Ping the solr'
  task 'index:ping' => [:environment] do
    command = 'curl -s SOLR_SUBS/admin/ping |grep -o -E "name=\"status\">([0-9]+)<"|cut -f2 -d\>|cut -f1 -d\<'.gsub(/SOLR_SUBS/, SOLR_UPDATE[Rails.env]['index_proxy']['allele'])
    output = `#{command}`
    if output.to_s.length > 0 && output.to_i == 0
      puts "#### #{SOLR_UPDATE[Rails.env]['index_proxy']['allele']} up and running!".green
    elsif output.empty?
      puts "#### #{SOLR_UPDATE[Rails.env]['index_proxy']['allele']} NOT running!".red
    else
      puts "#### #{SOLR_UPDATE[Rails.env]['index_proxy']['allele']} broken!".red
    end
  end

  desc 'Run the tests'
  task 'test', [:target, :load_db] => :environment do |t, args|
    args.with_defaults(:target => 'all')
    args.with_defaults(:load_db => true)

    Rake::Task['solr_bulk:db:load'].invoke if args[:load_db]

    PhenotypeAttemptsTest.new.run if %W{all phenotype_attempts}.include? args[:target]
    MiAttemptsTest.new.run if %W{all mi_attempts}.include? args[:target]
    AllelesTest.new.run if %W{all alleles}.include? args[:target]
    #GenesTest.new.run if %W{all genes}.include? args[:target]
  end

  desc 'generic_load'
  task 'index:generic_load', [:target] => :environment do |t, args|
    if args[:target].nil?
      puts "#### supply target!"
      exit
    end

    if ! LEGAL_TARGETS.include? args[:target]
      puts "#### unrecognised target '#{args[:target]}' - permitted: #{LEGAL_TARGETS.join(', ')}"
      exit
    end

    Rake::Task['solr_bulk:db:load'].invoke
    SolrBulk::Load.run([args[:target]])
  end

  desc 'Load the database with the new solr_bulk functions, tables and views'
  task 'db:load' => [:environment] do
    if ! DATABASE.has_key?(Rails.env)
      puts "#### cannot find '#{Rails.env}' in database.yml'"
      exit
    end

    password = DATABASE[Rails.env]['password']
    user = DATABASE[Rails.env]['username']
    database = DATABASE[Rails.env]['database']
    host = DATABASE[Rails.env]['host']
    port = DATABASE[Rails.env]['port'] || 5432

    command = "cd #{Rails.root}/script/solr_bulk; PGPASSWORD=\"#{password}\" psql --set 'env=#{Rails.env}' -U #{user} -d #{database} -h #{host} -p #{port} < solr_bulk.sql"

    puts command if Rails.env.development?

    output = `#{command}`
    puts output if output
  end

  desc "Download the index as csv - place in #{Rails.env}-solr.csv"
  task 'index:get_csv' => [:environment] do
    home = Dir.home
    command = "curl -o #{home}/Desktop/#{Rails.env}-solr.csv '#{SOLR_UPDATE[Rails.env]['index_proxy']['allele']}/select/?q=*:*&version=2.2&start=0&rows=100000&indent=on&wt=csv'"
    puts command
    output = `#{command}`
    puts output if output
  end

  desc 'get postgres version'
  task 'db:version' => [:environment] do
    ActiveRecord::Base.connection.execute('select version();')
  end

  desc 'normalize csv'
  task 'normalize_csv', [:filename] => :environment do |t, args|
    home = Dir.home
    args.with_defaults(:filename => "#{home}/Desktop/#{Rails.env}-solr.csv") if args[:filename].nil?

    if args[:filename].nil?
      raise "#### supply filename!".red
      exit
    end

    SolrBulk::Util.download_and_normalize args[:filename], SOLR_UPDATE[Rails.env]['index_proxy']['allele']
  end

  desc 'get and compare doc_factory & bulk generated item'
  task 'get_and_compare', [:target, :id] => :environment do |t, args|
    args.with_defaults(:target => 'phenotype_attempt')

    if args[:target] == 'phenotype_attempt'
      SolrBulk::Util.get_and_compare(args[:target], args[:id])
    else
      puts "#### '#{args[:target]}' not yet implemented!"
    end
  end

  desc 'reload single'
  task 'reload_single', [:target, :id] => :environment do |t, args|
    SolrBulk::Load.run_single(args[:target], args[:id])
  end

  desc 'show which solr'
  task 'which_solr' => [:environment] do
      puts "#### #{SOLR_UPDATE[Rails.env]['index_proxy']['allele']}"
  end

  desc 'grab docs from solr'
  task 'grab_solr', [:target, :id] => :environment do |t, args|
    proxy = SolrBulk::Proxy.new(SOLR_UPDATE[Rails.env]['index_proxy']['allele'])
    json = { :q => "type:#{args[:target]} id:#{args[:id]}" }
    docs = proxy.search(json)
    pp docs
  end

end
