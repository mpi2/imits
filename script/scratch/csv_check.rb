#!/usr/bin/env ruby

require 'pp'
require 'csv'

TEST = false
VERBOSE = false
SOLR_CSV = "/nfs/users/nfs_r/re4/Desktop/solr.csv"
HTGT_CSV = "/nfs/users/nfs_r/re4/Desktop/htgt.csv"

solr = {}
target_list = []
count = 0

CSV.foreach(SOLR_CSV, :headers => true, :header_converters => :symbol, :converters => :all) do |row|
  solr[row.fields[row.fields.size-2]] ||= []
  solr[row.fields[row.fields.size-2]].push(Hash[row.headers[0..-1].zip(row.fields[0..-1])])
  count += 1 if row.fields[row.fields.size-2] !~ /VG/
  break if TEST && count > 10
  target_list.push row.fields[2]
end

#pp solr

puts "#{SOLR_CSV} has #{count} lines"




htgt = {}
count = 0

CSV.foreach(HTGT_CSV, :headers => true, :header_converters => :symbol, :converters => :all) do |row|
  next if TEST && ! target_list.include?(row.fields[1])
  htgt[row.fields[1]] ||= []
  htgt[row.fields[1]].push(Hash[row.headers[0..-1].zip(row.fields[0..-1])])
  count += 1
end

puts "#{HTGT_CSV} has #{count} lines"


#	look in the htgt_download spreadsheet and match against the "allele_id" column of that spreadsheet
#	If the project doesn't look like "VG…" then you should be able to get a match.
#	If you can get a match:
#		a) Check the marker_symbol is identical for the allele-localhost and htgt_download row.
#		b) Check the status of the two rows is roughly correct:
#			If the type of the solr row is "mi_attempt or phenotype_attempt" then the status in the htgt row should be "Mice-GenotypeConfirmed" or "Phenotype Data Available".
#			If the type of the solr row is "allele" then the status in the htgt row should be "ES Targeting confirmed" or "Mice-Genotype Confirmed" or "Phenotype data available".

ignore = File.open( "ignore.log", "w"  )
missing = File.open( "missing.log", "w"  )
error = File.open( "error.log", "w"  )


unexpected_statuses = {}
unexpected_statuses2 = {}

total_counter = 0

solr.keys.each do |item|
  puts "#### item = #{item}" if VERBOSE
  puts "#### solr[item] = #{solr[item]}" if VERBOSE

  if item =~ /VG/
    ignore << item << "\n"
    next
  end

  solr[item].each do |thing|




    next if thing[:type] != 'mi_attempt'


total_counter += 1



    next if thing[:type] == 'gene'
    #next if ! thing[:marker_symbol] || thing[:marker_symbol].to_s.length < 1

    pp thing if VERBOSE

    puts "#### thing[:allele_id] = #{thing[:allele_id]}" if VERBOSE

    if ! htgt.has_key?(thing[:allele_id])
      missing << "Allele id: #{thing[:allele_id]} - symbol: '#{thing[:marker_symbol]}' \n"
      PP.pp(thing,missing)
      next
    end

    targets = htgt[thing[:allele_id]]
    puts "#### start:" if VERBOSE
    pp targets if VERBOSE
    puts "#### end" if VERBOSE

    targets.each do |target|



      # a) Check the marker_symbol is identical for the allele-localhost and htgt_download row.

      #if thing[:marker_symbol] && thing[:marker_symbol].to_s.length > 0 && target[:marker_symbol] != thing[:marker_symbol]
      if target[:marker_symbol] != thing[:marker_symbol]
        error << "#### allele: #{thing[:allele_id]} - Expected: '#{thing[:marker_symbol]}' - actual: '#{target[:marker_symbol]}'\n"
        PP.pp(thing,error)
        PP.pp(target,error)
      end

      # If the type of the solr row is "mi_attempt or phenotype_attempt" then the status in the htgt row should be "Mice-GenotypeConfirmed" or "Phenotype Data Available".

      solr_type = %W{mi_attempt phenotype_attempt}
      htgt_type = ["Mice-GenotypeConfirmed", "Phenotype Data Available"]
      if solr_type.include?(thing[:type])
        if ! htgt_type.include?(target[:pipeline_status])
          error << "#### allele: #{thing[:allele_id]} - Unexpected status: '#{target[:pipeline_status]}'\n"
          PP.pp(thing,error)
          PP.pp(target,error)
          unexpected_statuses[target[:pipeline_status]] ||= 0
          unexpected_statuses[target[:pipeline_status]] += 1
        end
      end

      # If the type of the solr row is "allele" then the status in the htgt row should be "ES Targeting confirmed" or "Mice-Genotype Confirmed" or "Phenotype data available".

      htgt_type = ["ES Targeting confirmed", "Mice-Genotype Confirmed", "Phenotype data available"]

      if thing[:type] == 'allele'
        if ! htgt_type.include?(target[:pipeline_status])
          error << "#### allele: #{thing[:allele_id]} - Unexpected status: '#{target[:pipeline_status]}'\n"
          PP.pp(thing,error)
          PP.pp(target,error)
          unexpected_statuses2[target[:pipeline_status]] ||= 0
          unexpected_statuses2[target[:pipeline_status]] += 1
        end
      end

    end

  end
end

ignore.close
missing.close
error.close

pp unexpected_statuses

pp unexpected_statuses2

puts "Processed #{total_counter}"

puts "done!"
