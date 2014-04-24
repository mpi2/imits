require 'pp'
require "#{Rails.root}/script/build_allele2.rb"

namespace :solr_allele2 do

  DATABASE = YAML.load_file("#{Rails.root}/config/database.yml")
  SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")

  desc 'Build the allele2 core'
  task 'build' => [:environment] do
    BuildAllele2.new.run
  end

  desc 'Ping the solr'
  task 'index:ping' => [:environment] do
    command = 'curl -s SOLR_SUBS/admin/ping |grep -o -E "name=\"status\">([0-9]+)<"|cut -f2 -d\>|cut -f1 -d\<'.gsub(/SOLR_SUBS/, SOLR_UPDATE[Rails.env]['index_proxy']['ck'])
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
    command = "curl -o #{home}/Desktop/#{Rails.env}-allele2-solr.csv '#{SOLR_UPDATE[Rails.env]['index_proxy']['ck']}/select/?q=*:*&version=2.2&start=0&rows=100000&indent=on&wt=csv'"
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
      #puts "#### get #{SOLR_UPDATE[Rails.env]['index_proxy']['ck']}"
      command = "curl -o #{home}/Desktop/#{Rails.env}-allele2-solr.csv '#{SOLR_UPDATE[Rails.env]['index_proxy']['ck']}/select/?q=type:gene&version=2.2&start=0&rows=100000&indent=on&wt=csv'"
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
      #break if counter >= 10
    end

    #pp header_hash
    #pp header_hash['mgi_accession_id']
    #exit

    #pp hash1
    #exit

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

end
