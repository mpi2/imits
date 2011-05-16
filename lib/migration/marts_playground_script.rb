#!/usr/bin/env ruby
#encoding: utf-8

idcc_targ_rep = Biomart::Dataset.new(
  "http://www.knockoutmouse.org/biomart",
  { :name => "idcc_targ_rep" }
)

dcc = Biomart::Dataset.new(
  "http://www.knockoutmouse.org/biomart",
  { :name => "dcc" }
)

y idcc_targ_rep.search(
  :filters => { "escell_clone" => ["EPD0021_2_A02", 'EPD0021_2_F04'] },
  :attributes => [
    "escell_clone",
    "pipeline",
    "mgi_accession_id",
    "allele_symbol_superscript"
  ],
  :process_results => true,
  :timeout => 300,
  :federate => [
    {
      :dataset => dcc,
      :filters => {},
      :attributes => ['marker_symbol']
    }
  ]
)
