require 'pp'
require "#{Rails.root}/script/build_allele2.rb"

namespace :solr_allele2 do

  DATABASE = YAML.load_file("#{Rails.root}/config/database.yml")
  SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")

  desc 'Build the allele2 core'
  task 'build' => [:environment] do
    BuildAllele2.new.run
  end

  desc "Download the allele2 index as csv - place in #{Rails.env}-allele2-solr.csv"
  task 'get_csv' => [:environment] do
    home = Dir.home
    #command = "curl -o #{home}/Desktop/#{Rails.env}-allele2-solr.csv '#{SOLR_UPDATE[Rails.env]['index_proxy']['ck']}/select/?q=*:*&version=2.2&start=0&rows=100000&indent=on&wt=csv'"
    command = "curl -o #{home}/Desktop/#{Rails.env}-allele2-solr.csv '#{SOLR_UPDATE[Rails.env]['index_proxy']['ck']}/select/?q=type:gene&version=2.2&start=0&rows=100000&indent=on&wt=csv'"
    puts command
    output = `#{command}`
    puts output if output
  end

  desc "Download the live gene2 index as csv"
  task 'get_csv_gene2' => [:environment] do
    home = Dir.home
    command = "curl -o #{home}/Desktop/live-gene2-solr.csv 'http://ikmc.vm.bytemark.co.uk:8983/solr/gene2/select/?q=*:*&version=2.2&start=0&rows=100000&indent=on&wt=csv'"
    puts command
    output = `#{command}`
    puts output if output
  end

  task 'compare_csv' => [:environment] do
    home = Dir.home
    hash1 = {}
    counter = 0
    headers = nil
    CSV.foreach("#{home}/Desktop/development-allele2-solr.csv", :headers => true) do |row|
      headers = row.headers if headers.nil?
      hash = Hash[row.headers[0..-1].zip(row.fields[0..-1])]
      hash1[row[4]] = hash
      counter += 1
      # break if counter >= 3
    end

    puts "#### allele2: count: #{counter} - keys: #{hash1.keys.size}"

    hash2 = {}
    counter = 0
    headers2 = nil
    CSV.foreach("#{home}/Desktop/live-gene2-solr.csv", :headers => true) do |row|
      headers2 = row.headers if headers2.nil?
      hash = Hash[row.headers[0..-1].zip(row.fields[0..-1])]
      hash2[row[18]] = hash
      counter += 1
      #   break if counter >= 3
    end

    puts "#### gene2: count: #{counter} - keys: #{hash2.keys.size}"

    diff = hash1.keys - hash2.keys
    puts "#### #{diff.size} in allele2 but not in gene2"

    #counter = 0
    #diff.each do |gene|
    #  if counter == 0
    #    pp hash1[gene]
    #  end
    #  puts gene
    #  counter += 1
    #  break if counter >= 5
    #end

    diff2 = hash2.keys - hash1.keys
    puts "#### #{diff2.size} in gene2 but not in allele2"

    #counter = 0
    #diff.each do |gene|
    #  if counter == 0
    #    pp hash2[gene]
    #  end
    #  puts gene
    #  counter += 1
    #  break if counter >= 5
    #end

    long = true

    CSV.open("#{home}/Desktop/diffs-gene2.csv", "wb") do |csv|
      csv << ['mgi_accession_id'] if ! long
      #pp hash2[key]
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

    #  pp hash1
    #  pp hash2
  end

end
