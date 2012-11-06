# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryKomp23Test < ActiveSupport::TestCase

  DEBUG = false

  context 'Reports::MiProduction::SummaryKomp23' do

    def new_gene_mi(factory, gene, attrs = {})
      return Factory.create(factory, {
          :consortium_name => 'BaSH',
          :production_centre_name => 'WTSI',
          :es_cell => TestDummy.create(:es_cell, :allele => Factory.create(:allele, :gene => Gene.find_by_marker_symbol!(gene)))
        }.merge(attrs)
      )
    end

    def new_non_wtsi_gene_gc_mi(gene, attrs = {})
      return Factory.create(:mi_attempt_genotype_confirmed, {
          :consortium_name => 'DTCC',
          :production_centre_name => 'UCD',
          :es_cell => TestDummy.create(:es_cell, :allele => Factory.create(:allele, :gene => Gene.find_by_marker_symbol!(gene)))
        }.merge(attrs)
      )
    end

    setup do
      (1..12).each {|i| Factory.create :gene, :marker_symbol => "Cbx#{i}"}

      TestDummy.mi_plan 'BaSH', 'WTSI', 'Cbx1',
              :number_of_es_cells_starting_qc => 2

      TestDummy.mi_plan 'BaSH', 'WTSI', 'Cbx2',
              :number_of_es_cells_starting_qc => 2,
              :number_of_es_cells_passing_qc => 1

      TestDummy.mi_plan 'BaSH', 'WTSI', 'Cbx3',
              :number_of_es_cells_starting_qc => 3,
              :number_of_es_cells_passing_qc => 2

      TestDummy.mi_plan 'BaSH', 'WTSI', 'Cbx4',
              :number_of_es_cells_starting_qc => 2,
              :number_of_es_cells_passing_qc => 0

      new_gene_mi(:mi_attempt, 'Cbx5')
      new_gene_mi(:mi_attempt, 'Cbx6')
      new_gene_mi(:mi_attempt_chimeras_obtained, 'Cbx7')
      new_gene_mi(:wtsi_mi_attempt_genotype_confirmed, 'Cbx8')
      new_gene_mi(:wtsi_mi_attempt_genotype_confirmed, 'Cbx9')
      new_gene_mi(:mi_attempt, 'Cbx10', :is_active => false)

      Factory.create :phenotype_attempt,
              :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', 'Cbx11'),
              :mi_attempt => new_non_wtsi_gene_gc_mi('Cbx11')

      Factory.create :phenotype_attempt_status_pdc,
              :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', 'Cbx12'),
              :mi_attempt => new_non_wtsi_gene_gc_mi('Cbx12')

      Reports::MiProduction::Intermediate.new.cache
    end

    should 'generate' do
      hash = Reports::MiProduction::SummaryKomp23.generate

      expected = {
        "Consortium" => "BaSH",
        "All genes" => 12,
        "ES cell QC" => 4,
        "ES QC confirmed" => 2,
        "ES QC failed" => 1,
        "Production Centre" => "WTSI",
        "Microinjections" => 6,
        "Chimaeras produced" => 1,
        "Genotype confirmed mice" => 2,
        "Microinjection aborted" => 1,
        "Gene Pipeline efficiency (%)" => 42,
        "Clone Pipeline efficiency (%)" => 41,
        "Registered for phenotyping" => 2,
        "Rederivation started" => '',
        "Rederivation completed" => '',
        "Cre excision started" => '',
        "Cre excision completed" => '',
        "Phenotyping started" => '',
        "Phenotyping completed" => 1,
        "Phenotyping aborted" => ''
      }

      got = {}

      hash[:table].column_names.each do |column_name|
        got[column_name] = hash[:table].column(column_name)[0]
      end

      assert_equal expected, got

      assert hash[:table].to_s.length > 0
    end

    should 'do generate detail' do
      puts 'do generate detail:' if DEBUG

      title2, report = Reports::MiProduction::SummaryKomp23.subsummary(:consortium => 'BaSH', :pcentre => 'BCM', :type => 'All')

      puts report.data.inspect if DEBUG

      assert report.to_s.length > 0
    end

    should '#cache' do
      Factory.create :phenotype_attempt
      generated = Reports::MiProduction::SummaryKomp23.generate
      Reports::MiProduction::SummaryKomp23.new.cache
      assert_equal generated[:csv], ReportCache.where(
        :name => Reports::MiProduction::SummaryKomp23.report_name,
        :format => :csv).first.data
      assert_equal generated[:html], ReportCache.where(
        :name => Reports::MiProduction::SummaryKomp23.report_name,
        :format => :html).first.data
    end

  end

end
