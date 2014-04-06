#!/usr/bin/env ruby

require 'pp'
require 'open-uri'

# see http://www.geneontology.org/GO.format.gaf-2_0.shtml#fields

#Column 	Content 	              Required?   Cardinality 	Example
#1 	        DB 	                      required 	  1 	        UniProtKB
#2 	        DB Object ID 	              required 	  1 	        P12345
#3 	        DB Object Symbol 	      required 	  1 	        PHO3
#4 	        Qualifier 	              optional 	  0 or greater 	NOT
#5 	        GO ID 	                      required 	  1 	        GO:0003993
#6 	        DB:Reference (|DB:Reference)  required 	  1 or greater 	PMID:2676709
#7 	        Evidence Code 	              required 	  1 	        IMP
#8 	        With (or) From 	              optional 	  0 or greater 	GO:0000346
#9 	        Aspect 	                      required 	  1 	        F
#10 	        DB Object Name 	              optional 	  0 or 1 	Toll-like receptor 4
#11 	        DB Object Synonym (|Synonym)  optional 	  0 or greater 	hToll|Tollbooth
#12 	        DB Object Type 	              required 	  1 	        protein
#13 	        Taxon(|taxon) 	              required 	  1 or 2 	taxon:9606
#14 	        Date 	                      required 	  1 	        20090118
#15 	        Assigned By 	              required 	  1 	        SGD
#16 	        Annotation Extension 	      optional 	  0 or greater 	part_of(CL:0000576)
#17 	        Gene Product Form ID 	      optional 	  0 or 1 	UniProtKB:P12345-2

ALL_COLUMNS = false
USE_FTP = false
FTP_LOCATION = 'ftp://ftp.informatics.jax.org/pub/reports/gene_association.mgi'
LOCAL_FILE_LOCATION = 'gene_association.mgi.original'

@genes_data = {}
@genes_data_array = []

@columns = [
  'DB', 'DB Object ID', 'DB Object Symbol', 'Qualifier', 'GO ID', 'DB Reference', 'Evidence Code', 'With From', 'Aspect',
  'DB Object Name', 'DB Object Synonym', 'DB Object Type', 'Taxon', 'Date', 'Assigned By', 'Annotation Extension', 'Gene Product Form ID'
]

@columns_hash = Hash[@columns.map.with_index.to_a]

def do_ftp; open(FTP_LOCATION, :proxy => nil) { |file| file.each_line { |line| process_line line } }; end

def do_local; File.open(LOCAL_FILE_LOCATION, "r") { |f| f.each_line { |line| process_line line } }; end

def process_line line
  return if line[0] == '!'
  row = line.strip.split("\t")
  product = {}

  if ALL_COLUMNS
    @columns.each { |column| product[column] = row[@columns_hash[column]] }
  else
    product['DB Object ID'] = row[@columns_hash['DB Object ID']]
    product['DB Object Synonym'] = row[@columns_hash['DB Object Synonym']]
  end

  @genes_data[row[@columns_hash['DB Object ID']]] = product if ! row[@columns_hash['DB Object Synonym']].to_s.empty?
end

def save_csv filename, data
  CSV.open(filename, "wb") do |csv|
    csv << data.first.keys
    data.each do |hash|
      csv << hash.values
    end
  end
end

def get_db
  rows = ActiveRecord::Base.connection.execute("select id, marker_symbol, mgi_accession_id from genes")
  rows.each do |row|
    if @genes_data.has_key?(row['mgi_accession_id'])
      @genes_data[row['mgi_accession_id']]['Marker symbol'] = row['marker_symbol']
      @genes_data_array.push(@genes_data[row['mgi_accession_id']].merge({ 'Marker symbol' => row['marker_symbol']}))
    end
  end
end

puts "#### using #{USE_FTP ? 'ftp' : 'local file'}"

do_ftp if USE_FTP
do_local if ! USE_FTP
get_db
save_csv "#{Dir.home}/Desktop/synonym_ck.csv", @genes_data_array

puts "#### done!"
