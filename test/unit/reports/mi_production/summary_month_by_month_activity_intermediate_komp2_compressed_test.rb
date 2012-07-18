# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryMonthByMonthActivityIntemediateKomp2CompressedTest < ActiveSupport::TestCase

  DEBUG = false

  context 'Reports::MiProduction::SummaryMonthByMonthActivityKomp2Compressed' do

    def new_gene_mi(factory, gene, attrs = {})
      return Factory.create(factory, {
          :consortium_name => 'BaSH',
          :production_centre_name => 'WTSI',
          :es_cell => TestDummy.create(:es_cell, gene)
        }.merge(attrs)
      )
    end

    def new_non_wtsi_gene_gc_mi(gene, attrs = {})
      return Factory.create(:mi_attempt_genotype_confirmed, {
          :consortium_name => 'DTCC',
          :production_centre_name => 'UCD',
          :es_cell => TestDummy.create(:es_cell, gene)
        }.merge(attrs)
      )
    end

    def new_non_wtsi_gene_gc_mi(gene, attrs = {})
      return Factory.create(:mi_attempt_genotype_confirmed, {
          :consortium_name => 'MARC',
          :production_centre_name => 'MARC',
          :es_cell => TestDummy.create(:es_cell, gene)
        }.merge(attrs)
      )
    end
end