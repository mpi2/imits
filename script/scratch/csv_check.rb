#!/usr/bin/env ruby

require 'pp'
require 'csv'

# but you need to write a quick script to check this in bulk, and the way to get the match between two rows of each spreadsheet is by matching the "project_ids" column  of your solr spreadsheet against the "allele_id" column of the htgt_download spreadsheet.
#
#Read that last sentence carefully …The data field I'm matching by is:
#
#htgt_download . allele_id  => this is the actual ikmc_project_id as it's held in htgt.
#You have to try to match this to …
#allele-localhost-8983 => project_ids (one element).
#
#This match will not always work. It only should be attempted for cases in the htgt_download spreadsheet where the flag eucomm=1 or eucomm_tools=1or komp=1. This will skip the regeneron cases (the projects that look like VG…)
#
#So one possible check is
#
#for each row in allele-localhost-8983
#	get project_id from the project_ids column (there always seems to be 1)
#	look in the htgt_download spreadsheet and match against the "allele_id" column of that spreadsheet
#	If the project doesn't look like "VG…" then you should be able to get a match.
#	If you can get a match:
#		a) Check the marker_symbol is identical for the allele-localhost and htgt_download row.
#		b) Check the status of the two rows is roughly correct:
#			If the type of the solr row is "mi_attempt or phenotype_attempt" then the status in the htgt row should be "Mice-GenotypeConfirmed" or "Phenotype Data Available".
#			If the type of the solr row is "allele" then the status in the htgt row should be "ES Targeting confirmed" or "Mice-Genotype Confirmed" or "Phenotype data available".
#
#For instance:
#allele-localhost-8983,  Row 4262 of the solr document you sent me has marker symbol Wnt10a, and project_ids 30675, and type = allele
#htgt-download spreadsheet, I search for the row with "allele_id" = 30675 (i.e. the "project id" in this spreadsheet ) and get this row:
#Row 4620: which has marker_symbol = Wnt10a (good) and status ES-Targeting confirmed (which is fine. It could have been a Mice-Genotype Confirmed or phenotype data available status as well).
#
#Here's another example:
#In allele-localhost-8983: Row 9067 of solr doc has Marker symbol = Exosc8 and project_ids=42081, and type = allele.
#htgt_download spreadsheet with matching project_id is row 12930, which has marker_symbol = Exosc8, status ES-Targeting Confirmed.
#
#Another example:
#allele-localhost-8983: Row 354 has type mi_attempt. Marker_symbol = Hdac1 and project_ids = 24146
#htgt_download has matching row with project_id 2236. Marker_symbol = Hdac1, status = Mice-PhenotypeDataAvailable.
#
#Note:
#If I find projects in the allele-localhost-8983 with names like 'VG11523' then you will NOT find them in the htgt_download spreadsheet, so that's not worth bothering with.
#Note:
#Sometimes the marker symbol may disagree. Try the mgi_accession_id instead, if have it on both sides.
#
#Can you run a check like this for all the rows? The rows where we have allele solr docs which _don't_ match should be either Regeneron (VG…) or possibly NorCOMM stuff. Can you see the compare script should be a small bit of perl: 2 csv file reads, making a hash of entries on both sides keyed by project_id, followed by a comparison of statuses in each hash?
#
#
#Thanks,
#
#Vivek
#
#Not all the data can be immediately matched. The KOMP-Regeneron projects can't be matched, for instance.

SOLR_CSV = "/nfs/users/nfs_r/re4/Desktop/solr.csv"
HTGT_CSV = "/nfs/users/nfs_r/re4/Desktop/htgt.csv"

solr = {}
count = 0

CSV.foreach(SOLR_CSV, :headers => true, :header_converters => :symbol, :converters => :all) do |row|
  solr[row.fields[row.fields.size-2]] ||= []
  solr[row.fields[row.fields.size-2]].push(Hash[row.headers[0..-1].zip(row.fields[0..-1])])
  count += 1 if row.fields[row.fields.size-2] !~ /VG/
end

puts "#{SOLR_CSV} has #{count} lines"

htgt = {}
count = 0

CSV.foreach(HTGT_CSV, :headers => true, :header_converters => :symbol, :converters => :all) do |row|
  htgt[row.fields[1]] ||= []
  htgt[row.fields[1]].push(Hash[row.headers[0..-1].zip(row.fields[0..-1])])
  count += 1
end

puts "#{HTGT_CSV} has #{count} lines"

ignore = File.open( "ignore.log", "w"  )
missing = File.open( "missing.log", "w"  )
error = File.open( "error2.log", "w"  )

unexpected_statuses = {}
unexpected_statuses2 = {}

total_counter = 0
fail_counter = 0

solr.keys.each do |item|

  if item =~ /VG/
    ignore << item << "\n"
    next
  end

  solr[item].each do |solr_doc|

    total_counter += 1

    next if solr_doc[:type] == 'gene'

    if ! htgt.has_key?(item)
      missing << "\n#### Allele id: #{solr_doc[:allele_id]} - symbol: '#{solr_doc[:marker_symbol]}' \n\n"
      PP.pp(solr_doc,missing)
      next
    end

    targets = htgt[item]

    error_found = false

    targets.each do |htgt_row|

      next if htgt_row[:pipeline_status] == "Regeneron"

      # This match will not always work. It only should be attempted for cases in the htgt_download spreadsheet where the
      # flag eucomm=1 or eucomm_tools=1or komp=1. This will skip the regeneron cases (the projects that look like VG…)

      #next if ! (htgt_row[:eucomm] == '1' || htgt_row[:eucomm_tools] == '1' || htgt_row[:komp] == '1')

      # a) Check the marker_symbol is identical for the allele-localhost and htgt_download row.

      if htgt_row[:marker_symbol] != solr_doc[:marker_symbol]
        error << "\n#### project: #{item} - allele: #{solr_doc[:allele_id]} - Expected: '#{solr_doc[:marker_symbol]}' - actual: '#{htgt_row[:marker_symbol]}'\n\n"
        PP.pp(solr_doc,error)
        error << "\n\n"
        PP.pp(htgt_row,error)
        error_found = true
      end

      # If the type of the solr row is "mi_attempt or phenotype_attempt" then the status in the htgt row should be "Mice-GenotypeConfirmed" or "Phenotype Data Available".

      solr_type = %W{mi_attempt phenotype_attempt}
      htgt_type = ["Mice - Genotype confirmed", "Phenotype Data Available", "Mice - Phenotype Data Available"]

      if solr_type.include?(solr_doc[:type])
        if ! htgt_type.include?(htgt_row[:pipeline_status])
          error << "\n#### 1. project: #{item} - allele: #{solr_doc[:allele_id]} - Unexpected status: '#{htgt_row[:pipeline_status]}'\n\n"
          PP.pp(solr_doc,error)
          error << "\n\n"
          PP.pp(htgt_row,error)
          unexpected_statuses[htgt_row[:pipeline_status]] ||= 0
          unexpected_statuses[htgt_row[:pipeline_status]] += 1
          error_found = true
        end
      end

      # If the type of the solr row is "allele" then the status in the htgt row should be "ES Targeting confirmed" or "Mice-Genotype Confirmed" or "Phenotype data available".

      htgt_type = ["ES Cells - Targeting Confirmed", "ES Targeting confirmed", "Mice-Genotype Confirmed", "Phenotype data available", 'Mice - Genotype confirmed', "Mice - Phenotype Data Available", "Mice - Microinjection in progress"]

      if solr_doc[:type] == 'allele'
        if ! htgt_type.include?(htgt_row[:pipeline_status])
          error << "\n#### 2. project: #{item} - allele: #{solr_doc[:allele_id]} - Unexpected status: '#{htgt_row[:pipeline_status]}'\n\n"
          PP.pp(solr_doc,error)
          error << "\n\n"
          PP.pp(htgt_row,error)
          unexpected_statuses2[htgt_row[:pipeline_status]] ||= 0
          unexpected_statuses2[htgt_row[:pipeline_status]] += 1
          error_found = true
        end
      end

#      break if ! fail_counter
    end

    fail_counter += 1 if error_found

  end
end

ignore.close
missing.close
error.close

if ! unexpected_statuses.empty?
  puts "#### unexpected_statuses:"
  pp unexpected_statuses
end

if ! unexpected_statuses2.empty?
  puts "#### unexpected_statuses2:"
  pp unexpected_statuses2
end

puts "Processed #{fail_counter}/#{total_counter}"

puts "done!"
