
namespace :solr_bulk do

  SOLR_BULK = YAML.load_file("#{Rails.root}/config/solr_bulk.yml")
  DATABASE = YAML.load_file("#{Rails.root}/config/database.yml")
  SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")
  LEGAL_TARGETS = %W{genes phenotype_attempts mi_attempts alleles all}

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
