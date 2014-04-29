require 'pp'
require "#{Rails.root}/script/build_allele2.rb"
#require 'zipruby'

namespace :solr_allele2 do

  DATABASE = YAML.load_file("#{Rails.root}/config/database.yml")
  SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")

  desc 'Build the allele2 core'
  task 'build' => [:environment] do
    BuildAllele2.new.run
  end

  desc 'Ping the solr'
  task 'index:ping' => [:environment] do
    command = 'curl -s SOLR_SUBS/admin/ping |grep -o -E "name=\"status\">([0-9]+)<"|cut -f2 -d\>|cut -f1 -d\<'.gsub(/SOLR_SUBS/, SOLR_UPDATE[Rails.env]['index_proxy']['allele2'])
    output = `#{command}`
    if output.to_s.length > 0 && output.to_i == 0
      puts "#### #{SOLR_UPDATE[Rails.env]['index_proxy']['allele']} up and running!".green
    elsif output.empty?
      puts "#### #{SOLR_UPDATE[Rails.env]['index_proxy']['allele']} NOT running!".red
    else
      puts "#### #{SOLR_UPDATE[Rails.env]['index_proxy']['allele']} broken!".red
    end
  end

  desc "Download the allele2 index as csv - place in #{Rails.env}-allele2-solr.csv"
  task 'get_csv' => [:environment] do
    home = Dir.home
    command = "curl -o #{home}/Desktop/#{Rails.env}-allele2-solr.csv '#{SOLR_UPDATE[Rails.env]['index_proxy']['allele2']}/select/?q=*:*&version=2.2&start=0&rows=100000&indent=on&wt=csv'"
    puts command
    output = `#{command}`
    puts output if output
  end

  task 'get_csv_gene2' => [:environment] do
    home = Dir.home
    puts "#### get http://ikmc.vm.bytemark.co.uk:8983/solr/gene2}"
    command = "curl -o #{home}/Desktop/live-gene2-solr.csv 'http://ikmc.vm.bytemark.co.uk:8983/solr/gene2/select/?q=*:*&version=2.2&start=0&rows=100000&indent=on&wt=csv'"
    puts command
    output = `#{command}`
    puts output if output
  end

  task 'compare_csv' => [:environment] do
    home = Dir.home
    filename = "#{home}/Desktop/#{Rails.env}-allele2-solr.csv"
    if ! File.exist?(filename)
      #puts "#### get #{SOLR_UPDATE[Rails.env]['index_proxy']['allele2']}"
      command = "curl -o #{home}/Desktop/#{Rails.env}-allele2-solr.csv '#{SOLR_UPDATE[Rails.env]['index_proxy']['allele2']}/select/?q=type:gene&version=2.2&start=0&rows=100000&indent=on&wt=csv'"
      puts command
      output = `#{command}`
      puts output if output
    end

    filename2 = "#{home}/Desktop/live-gene2-solr.csv"
    if ! File.exist?(filename2)
      Rake::Task['solr_allele2:get_csv_gene2'].invoke
    end

    hash1 = {}
    counter = 0
    headers = nil
    header_hash = nil
    CSV.foreach(filename, :headers => true) do |row|
      headers = row.headers if headers.nil?
      hash = Hash[row.headers[0..-1].zip(row.fields[0..-1])]

      header_hash = Hash[headers.map.with_index.to_a] if header_hash.nil?

      hash1[row[header_hash['mgi_accession_id']]] = hash
      counter += 1
    end

    puts "#### allele2: count: #{counter} - keys: #{hash1.keys.size}"

    hash2 = {}
    counter = 0
    headers2 = nil
    header_hash = nil
    CSV.foreach(filename2, :headers => true) do |row|
      headers2 = row.headers if headers2.nil?
      hash = Hash[row.headers[0..-1].zip(row.fields[0..-1])]

      header_hash = Hash[headers2.map.with_index.to_a] if header_hash.nil?

      hash2[row[header_hash['MGI']]] = hash
      counter += 1
    end

    puts "#### gene2: count: #{counter} - keys: #{hash2.keys.size}"

    diff = hash1.keys - hash2.keys
    puts "#### #{diff.size} in allele2 but not in gene2"

    diff2 = hash2.keys - hash1.keys
    puts "#### #{diff2.size} in gene2 but not in allele2"

    long = true

    CSV.open("#{home}/Desktop/diffs-gene2.csv", "wb") do |csv|
      csv << ['mgi_accession_id'] if ! long
      csv << headers2 if long
      diff2.each do |key|
        next if ! hash2.has_key? key
        csv << [key] if ! long
        csv << hash2[key].values if long
      end
    end

    CSV.open("#{home}/Desktop/diffs-allele2.csv", "wb") do |csv|
      csv << ['mgi_accession_id'] if ! long
      csv << headers if long
      diff.each do |key|
        next if ! hash1.has_key? key
        csv << [key] if ! long
        csv << hash1[key].values if long
      end
    end
  end

  def save_hash_as_csv filename, hash2, diff2
    CSV.open(filename, "wb") do |csv|
      csv << @headers2
      diff2.each do |key|
        next if ! hash2.has_key? key
        csv << hash2[key].values
      end
    end
  end

  def get_hash_from_csv filename, key
    hash2 = {}
    @counter = 0
    @headers2 = nil
    header_hash = nil
    CSV.foreach(filename, :headers => true) do |row|
      @headers2 = row.headers if @headers2.nil?
      hash = Hash[row.headers[0..-1].zip(row.fields[0..-1])]

      header_hash = Hash[@headers2.map.with_index.to_a] if header_hash.nil?

      hash2[row[header_hash[key]]] = hash
      @counter += 1
    end
    hash2
  end

  def compare_csv config
    filename = config['file1']['source']
    filename2 = config['file2']['source']
    filenameo = config['file1']['destination']
    filename2o = config['file2']['destination']

    hash1 = get_hash_from_csv filename, config['file1']['key']

    headers1 = @headers2

    blurb = "#### #{config['file1']['name']}: count: #{@counter} - keys: #{hash1.keys.size}"

    hash2 = get_hash_from_csv filename2, config['file2']['key']

    headers2 = @headers2

    blurb += "\n#### #{config['file2']['name']}: count: #{@counter} - keys: #{hash2.keys.size}"

    diff = hash1.keys - hash2.keys
    blurb += "\n#### #{diff.size} in #{config['file1']['name']} but not in #{config['file2']['name']} - #{filename2o}"

    diff2 = hash2.keys - hash1.keys
    blurb += "\n#### #{diff2.size} in #{config['file2']['name']} but not in #{config['file1']['name']} - #{filenameo}"

    puts blurb
    puts ""

    @headers2 = headers2

    save_hash_as_csv filenameo, hash2, diff2

    @headers2 = headers1

    save_hash_as_csv filename2o, hash1, diff

    home = Dir.home

    #File.open("#{home}/Desktop/readme.txt", 'w') {|f| f.write(blurb) }
    #
    #Zip::Archive.open("#{home}/Desktop/#{config['file1']['name']}-#{config['file2']['name']}.zip", Zip::CREATE| Zip::TRUNC) do |ar|
    #  # specifies compression level: ..., Zip::CREATE, Zip::BEST_SPEED) do |ar|
    #
    #  ar.add_file("#{home}/Desktop/readme.txt")
    #  ar.add_file(config['file1']['source'])
    #  ar.add_file(config['file2']['source'])
    #  ar.add_file(config['file1']['destination'])
    #  ar.add_file(config['file2']['destination'])
    #end
    #
    #FileUtils.rm(config['file1']['destination'])
    #FileUtils.rm(config['file2']['destination'])
    #FileUtils.rm("#{home}/Desktop/readme.txt")
  end

  task 'compare_csv_generic' => [:environment] do
    home = Dir.home

    configs = [
    #{
    #  'file1' => {'name' => 'dcc', 'source' => "#{home}/Desktop/ikmc-dcc-gene_details.csv", 'key' => 'mgi_accession_id', 'destination' => "#{home}/Desktop/ikmc-dcc-gene_details-output.csv"},
    #  'file2' => {'name' => 'biomart', 'source' => "#{home}/Desktop/jax_mart_export.csv", 'key' => 'MGI ID', 'destination' => "#{home}/Desktop/jax_mart_export-output.csv"}
    #},
    #{
    #  'file1' => {'name' => 'gene2', 'source' => "#{home}/Desktop/localhost-gene2.csv", 'key' => 'MGI', 'destination' => "#{home}/Desktop/localhost-gene2-output.csv"},
    #  'file2' => {'name' => 'biomart', 'source' => "#{home}/Desktop/jax_mart_export.csv", 'key' => 'MGI ID', 'destination' => "#{home}/Desktop/jax_mart_export-output2.csv"}
    #},
    {
      'file1' => {'name' => 'allele2', 'source' => "#{home}/Desktop/localhost-allele2.csv", 'key' => 'mgi_accession_id', 'destination' => "#{home}/Desktop/localhost-allele2-output.csv"},
      'file2' => {'name' => 'gene2', 'source' => "#{home}/Desktop/localhost-gene2.csv", 'key' => 'MGI', 'destination' => "#{home}/Desktop/localhost-gene2-output2.csv"}
    },
    #{
    #  'file1' => {'name' => 'allele2-full', 'source' => "#{home}/Desktop/localhost-allele2-full.csv", 'key' => 'mgi_accession_id', 'destination' => "#{home}/Desktop/localhost-allele2-full-output.csv"},
    #  'file2' => {'name' => 'gene2', 'source' => "#{home}/Desktop/localhost-gene2.csv", 'key' => 'MGI', 'destination' => "#{home}/Desktop/localhost-gene2-output3.csv"}
    #}
  ]

  configs.each do |config|
    compare_csv config
  end

  end
end
