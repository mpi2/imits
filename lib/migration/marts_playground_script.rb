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
  :filters => { "escell_clone" => ['mirKO_ES_PuDtk_4C1', 'EUC0018f04', 'EPD0059_3_E01'] },
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
