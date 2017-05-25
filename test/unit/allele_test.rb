# encoding: utf-8

require 'test_helper'

class AlleleTest < ActiveSupport::TestCase
  context 'Allele' do

    setup do
      Factory.create :allele
    end


  # validate :allele_type; value is restricted to the following values. :inclusion => { :in => ALLELE_OPTIONS.keys + CRISPR_ALLELE_OPTIONS.keys }, :allow_nil => true
  # validate :allele_subtype; value is restricted to the following values. :inclusion => { :in => CRISPR_ALLELE_SUB_TYPE_OPTIONS}, :allow_nil => true
  # validate allele belongs to either an ES Cell or a colony.
  # validate mgi_allele_accession_id; format must satisfy /^MGI\:\d+$/

  # updating genbank file of an allele must update upstream genbank files of colonies produced by Mi Attempts and Mouse Allelel Mods.


  end
end
