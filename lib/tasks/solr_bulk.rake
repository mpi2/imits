
require "#{Rails.root}/script/solr_bulk/test/phenotype_attempts_test.rb"
require "#{Rails.root}/script/solr_bulk/test/mi_attempts_test.rb"
require "#{Rails.root}/script/solr_bulk/test/genes_test.rb"

namespace :solr_bulk do

  SOLR_BULK = YAML.load_file("#{Rails.root}/config/solr_bulk.yml")
  DATABASE = YAML.load_file("#{Rails.root}/config/database.yml")
  SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")
  LEGAL_TARGETS = %W{genes phenotype_attempts mi_attempts alleles all}

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
    args.with_defaults(:load_db => false)

    Rake::Task['solr_bulk:db:load'].invoke if args[:load_db]

    PhenotypeAttemptsTest.new.run if %W{all phenotype_attempts}.include? args[:target]
    MiAttemptsTest.new.run if %W{all mi_attempts}.include? args[:target]
    GenesTest.new.run if %W{all genes}.include? args[:target]
    #AllelesTest.new.run if %W{all alleles}.include? args[:target]
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

    command = "cd #{Rails.root}/script/solr_bulk; PGPASSWORD=#{password} psql -U #{user} -d #{database} -h #{host} -p #{port} < solr_bulk.sql"
    puts command
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

end