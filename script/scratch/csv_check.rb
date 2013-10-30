#!/usr/bin/env ruby



#Hello Richard,
#
#The javascript widget you showed me with the "Product Details" link looks good. We should have that ready to go (live, really) the moment you have verified the check you are doing for the project-ids is good.
#
#I didn't have open-office, so I had to install that first. Then that crashed my computer the first time, when I was trying to open these things.
#
#Anyway, the images you include in each worksheet show the solr project id row matching the current ikmc project id stored in htgt (I'm comparing the numbers in your javascript widget "product id" column with the numbers in the "Project: …" number in the martsearch web page screenshot).
#
#That's comforting, but you need to write a quick script to check this in bulk, and the way to get the match between two rows of each spreadsheet is by matching the "project_ids" column  of your solr spreadsheet against the "allele_id" column of the htgt_download spreadsheet.
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



#Not all the data can be immediately matched. The KOMP-Regeneron projects can't be matched, for instance.


require 'pp'
require 'csv'

#tickers = {}
#
#CSV.foreach("stocks.csv", :headers => true, :header_converters => :symbol, :converters => :all) do |row|
#  tickers[row.fields[0]] = Hash[row.headers[1..-1].zip(row.fields[1..-1])]
#end

htgt = {}
count = 0

CSV.foreach("/nfs/users/nfs_r/re4/Desktop/htgt.csv", :headers => true, :header_converters => :symbol, :converters => :all) do |row|
  htgt[row.fields[1]] ||= []
  htgt[row.fields[1]].push(Hash[row.headers[1..-1].zip(row.fields[1..-1])])
  count += 1
  # break if count > 10
end

#pp htgt

puts "/nfs/users/nfs_r/re4/Desktop/htgt.csv has #{count} lines"





solr = {}
count = 0

CSV.foreach("/nfs/users/nfs_r/re4/Desktop/solr.csv", :headers => true, :header_converters => :symbol, :converters => :all) do |row|
  solr[row.fields[row.fields.size-2]] ||= []
  solr[row.fields[row.fields.size-2]].push(Hash[row.headers[1..-1].zip(row.fields[1..-1])])
  count += 1
  break if count > 10
end

pp solr

puts "/nfs/users/nfs_r/re4/Desktop/solr.csv has #{count} lines"


#	look in the htgt_download spreadsheet and match against the "allele_id" column of that spreadsheet
#	If the project doesn't look like "VG…" then you should be able to get a match.
#	If you can get a match:
#		a) Check the marker_symbol is identical for the allele-localhost and htgt_download row.
#		b) Check the status of the two rows is roughly correct:
#			If the type of the solr row is "mi_attempt or phenotype_attempt" then the status in the htgt row should be "Mice-GenotypeConfirmed" or "Phenotype Data Available".
#			If the type of the solr row is "allele" then the status in the htgt row should be "ES Targeting confirmed" or "Mice-Genotype Confirmed" or "Phenotype data available".


solr.keys.each do |item|
  puts "#### item = #{item}"
  puts "#### solr[item] = #{solr[item]}"

  solr[item].each do |thing|

    pp thing

    puts "#### thing[:allele_id] = #{thing[:allele_id]}"

    next if ! htgt.has_key?(thing[:allele_id])

    targets = htgt[thing[:allele_id]]
    puts "#### start:"
    pp targets
    puts "#### end"

  end
end







#exit
#
#htgt_hash = {}
#solr_hash = {}
#
#count = 0
#File.open("/nfs/users/nfs_r/re4/Desktop/htgt.csv").each do |line|
#  line.chomp!
#  puts line
#  break
#
#  #htgt_hash[]
#
#  count += 1
#end
#
#puts "/nfs/users/nfs_r/re4/Desktop/htgt.csv has #{count} lines"
#
#count = 0
#File.open("/nfs/users/nfs_r/re4/Desktop/solr.csv").each do |line|
#  line.chomp!
#  #puts line
#  #break
#  count += 1
#end
#
#puts "/nfs/users/nfs_r/re4/Desktop/solr.csv has #{count} lines"
