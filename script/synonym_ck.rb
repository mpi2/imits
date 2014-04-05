#!/usr/bin/env ruby

# This script is used to download the nightly dump of the Solr
# index XMLs from the KOMP-DCC (Jackson Lab) and insert the
# data into a staging database ready for it to be biomartized.

require 'pp'
#require 'optparse'
#require 'yaml'
#require 'net/ftp'
#require 'xmlsimple'
#require 'csv'
#require 'net/http'
#require 'uri'
#require 'biomart'
#require 'json'
#require 'dbi'
#require 'terminal-table/import'
require 'open-uri'

# Method to download the XML file dump from jax and extract it
# into our directory.
#def download_xml_files
#  ftp = Net::FTP.new('ftp.informatics.jax.org')
#  ftp.login
#  ftp.chdir('pub')
#  ftp.chdir('reports')
#  ftp.getbinaryfile('gene_association.mgi')
#  ftp.close
#end
#
##ftp://ftp.informatics.jax.org/pub/reports/gene_association.mgi
#
#puts "Downloading and gene_association.mgi..."
#download_xml_files()
#
#exit

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

genes_data = {}
genes_data_array = []

columns = [
  'DB',
  'DB Object ID',
  'DB Object Symbol',
  'Qualifier',
  'GO ID',
  'DB Reference',
  'Evidence Code',
  'With From',
  'Aspect',
  'DB Object Name',
  'DB Object Synonym',
  'DB Object Type',
  'Taxon',
  'Date',
  'Assigned By',
  'Annotation Extension',
  'Gene Product Form ID'
]

#columns_symbols = columns.map {|column| column.downcase.to_sym }

columns_hash = Hash[columns.map.with_index.to_a]

#url = 'ftp://ftp.informatics.jax.org/pub/reports/gene_association.mgi'
#open(url, :proxy => nil) do |file|
#  headers = file.readline.strip.split("\t")

File.open("gene_association.mgi.original", "r") do |f|
  f.each_line do |line|

    next if line[0] == '!'

    #headers = line.strip.split("\t")
    #db = headers.index('DB')
    #db_object_id = headers.index('DB Object ID')
    #db_object_symbol = headers.index('DB Object Symbol')
    #qualifier = headers.index('Qualifier')
    #go_id = headers.index('GO ID')
    #db_reference = headers.index('DB:Reference')
    #evidence_code = headers.index('Evidence Code')
    #with_from = headers.index('With (or) From')
    #aspect = headers.index('Aspect')
    #db_object_name = headers.index('DB Object Name')
    #db_object_synonym  = headers.index('DB Object Synonym ')
    #db_object_type = headers.index('DB Object Type')
    #taxon = headers.index('Taxon')
    #date = headers.index('Date')
    #assigned_by = headers.index('Assigned By')
    #annotation_extension = headers.index('Annotation Extension')
    #gene_product_form_id = headers.index('Gene Product Form ID')

    #file.each_line do |line|
    #  row = line.strip.gsub(/\"/, '').split("\t")
    #genes_data[row[mgi_accession_index]] = {
    #
    #  #'db' => row[db],
    #  #'db_object_id' => row[db_object_id],
    #  #'db_object_symbol'   => row[db_object_symbol],
    #  #'qualifier'           => row[qualifier],
    #  #'go_id'         => row[go_id],
    #  #'db_reference'           => row[db_reference],
    #  #'evidence_code'        => row[evidence_code],
    #  #'with_from'  => row[with_from],
    #  #'aspect'  => row[aspect],
    #  #'db_object_name'  => row[db_object_name],
    #  #'db_object_synonym'  => row[db_object_synonym],
    #  #'db_object_type'  => row[db_object_type],
    #  #'taxon'  => row[taxon],
    #  #'date'  => row[date],
    #  #'assigned_by'  => row[assigned_by],
    #  #'annotation_extension'  => row[annotation_extension],
    #  #'gene_product_form_id'  => row[gene_product_form_id]
    #
    #  columns.each do |column|
    #  end
    #}

    #row = line.strip.gsub(/\"/, '').split("\t")
    row = line.strip.split("\t")

    product = {}
    #columns.each do |column|
    #  product[column] = row[columns_hash[column]]
    #end

    product['DB Object ID'] = row[columns_hash['DB Object ID']]
    product['DB Object Synonym'] = row[columns_hash['DB Object Synonym']]

    genes_data[row[columns_hash['DB Object ID']]] = product if ! row[columns_hash['DB Object Synonym']].to_s.empty?

    genes_data_array.push product if ! row[columns_hash['DB Object Synonym']].to_s.empty?

    #break

  end
end
#end

#pp genes_data

home = Dir.home
filename = "#{home}/Desktop/synonym_ck.csv"

CSV.open(filename, "wb") do |csv|
  csv << genes_data_array.first.keys
  genes_data_array.each do |hash|
    csv << hash.values
  end
end
