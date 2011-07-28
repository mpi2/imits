#!/usr/bin/env ruby
#encoding: utf-8

DCC_DATASET = Biomart::Dataset.new(
  'http://www.knockoutmouse.org/biomart',
  { :name => 'dcc' }
)

EsCell.find(:all, :conditions => {'mgi_accession_id' => nil}).each do |es_cell|
  results = DCC_DATASET.search(
    :filters => { 'marker_symbol' => es_cell.marker_symbol },
    :attributes => ['marker_symbol', 'mgi_accession_id'],
    :process_results => true,
    :timeout => 600
  ).first

  next if results.blank?

  puts "Updating mgi_accession_id of #{es_cell.name} (#{es_cell.marker_symbol}) to #{results['mgi_accession_id']}"
  es_cell.mgi_accession_id = results['mgi_accession_id']
  es_cell.save!
end
