#!/usr/bin/env ruby

require 'pp'
require 'csv'

SOLR_CSV = "/nfs/users/nfs_r/re4/Desktop/solr.csv"
HTGT_CSV = "/nfs/users/nfs_r/re4/Desktop/htgt.csv"

solr = {}
count = 0

CSV.foreach(SOLR_CSV, :headers => true, :header_converters => :symbol, :converters => :all) do |row|
  solr[row.fields[row.fields.size-2]] ||= []
  solr[row.fields[row.fields.size-2]].push(Hash[row.headers[0..-1].zip(row.fields[0..-1])])
  count += 1 if row.fields[row.fields.size-2] !~ /VG/
  #break if count >= 10
end

puts "#{SOLR_CSV} has #{count} lines"

htgt = {}
count = 0

CSV.foreach(HTGT_CSV, :headers => true, :header_converters => :symbol, :converters => :all) do |row|
  htgt[row.fields[1]] ||= []
  htgt[row.fields[1]].push(Hash[row.headers[0..-1].zip(row.fields[0..-1])])
  count += 1
  #break if count >= 10
end

puts "#{HTGT_CSV} has #{count} lines"

@ignore = File.open( "ignore2.log", "w"  )
@missing = File.open( "missing2.log", "w"  )
@error = File.open( "error2.log", "w"  )

@unexpected_statuses = {}
@unexpected_statuses2 = {}

total_counter = 0
fail_counter = 0




def check_items(targets, solr_doc)
  targets.each do |htgt_row|

    next if htgt_row[:pipeline_status] == "Regeneron"

    # This match will not always work. It only should be attempted for cases in the htgt_download spreadsheet where the
    # flag eucomm=1 or eucomm_tools=1or komp=1. This will skip the regeneron cases (the projects that look like VG…)

    #next if ! (htgt_row[:eucomm] == '1' || htgt_row[:eucomm_tools] == '1' || htgt_row[:komp] == '1')

    # a) Check the marker_symbol is identical for the allele-localhost and htgt_download row.

    if htgt_row[:marker_symbol] != solr_doc[:marker_symbol]
      @error << "\n#### project: #{solr_doc[:project_ids][0]} - allele: #{solr_doc[:allele_id]} - Expected: '#{solr_doc[:marker_symbol]}' - actual: '#{htgt_row[:marker_symbol]}'\n\n"
      PP.pp(solr_doc,@error)
      @error << "\n\n"
      PP.pp(htgt_row,@error)
      next
    end

    # If the type of the solr row is "mi_attempt or phenotype_attempt" then the status in the htgt row should be "Mice-GenotypeConfirmed" or "Phenotype Data Available".

    solr_type = %W{mi_attempt phenotype_attempt}
    htgt_type = ["Mice - Genotype confirmed", "Phenotype Data Available", "Mice - Phenotype Data Available"]

    if solr_type.include?(solr_doc[:type])
      if ! htgt_type.include?(htgt_row[:pipeline_status])
        @error << "\n#### 1. allele: #{solr_doc[:allele_id]} - Unexpected status: '#{htgt_row[:pipeline_status]}'\n\n"
        #PP.pp(solr_doc,@error)
        #PP.pp(htgt_row,@error)
        @unexpected_statuses[htgt_row[:pipeline_status]] ||= 0
        @unexpected_statuses[htgt_row[:pipeline_status]] += 1
        next
      end
    end

    # If the type of the solr row is "allele" then the status in the htgt row should be "ES Targeting confirmed" or "Mice-Genotype Confirmed" or "Phenotype data available".

    htgt_type = ["ES Cells - Targeting Confirmed", "ES Targeting confirmed", "Mice-Genotype Confirmed", "Phenotype data available", 'Mice - Genotype confirmed', "Mice - Phenotype Data Available"]

    if solr_doc[:type] == 'allele'
      if ! htgt_type.include?(htgt_row[:pipeline_status])
        @error << "\n#### 2. allele: #{solr_doc[:allele_id]} - Unexpected status: '#{htgt_row[:pipeline_status]}'\n\n"
        #PP.pp(solr_doc,@error)
        #PP.pp(htgt_row,@error)
        @unexpected_statuses2[htgt_row[:pipeline_status]] ||= 0
        @unexpected_statuses2[htgt_row[:pipeline_status]] += 1
        next
      end
    end

    return true
  end

  return false
end




solr.keys.each do |item|

  if item =~ /VG/
    @ignore << item << "\n"
    next
  end

  solr[item].each do |solr_doc|

    total_counter += 1

    next if solr_doc[:type] == 'gene'

    if ! htgt.has_key?(item)
      @missing << "\n#### Allele id: #{solr_doc[:allele_id]} - symbol: '#{solr_doc[:marker_symbol]}' \n\n"
      PP.pp(solr_doc,@missing)
      next
    end

    targets = htgt[item]

    error_found = check_items(targets, solr_doc)

    fail_counter += 1 if error_found

  end
end

@ignore.close
@missing.close
@error.close

if ! @unexpected_statuses.empty?
  puts "#### @unexpected_statuses:"
  pp @unexpected_statuses
end

if ! @unexpected_statuses2.empty?
  puts "#### @unexpected_statuses2:"
  pp @unexpected_statuses2
end

puts "Processed #{fail_counter}/#{total_counter}"

puts "done!"
