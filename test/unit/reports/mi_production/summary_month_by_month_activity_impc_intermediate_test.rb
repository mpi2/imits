# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryMonthByMonthActivityImpcIntermediateTest < ActiveSupport::TestCase

  context 'Reports::MiProduction::SummaryMonthByMonthActivityImpcIntermediate' do

    def new_gene_mi(factory, gene, consortia, production_centre, attrs = {})
      return Factory.create(factory, {
          :consortium_name => consortia,
          :production_centre_name => production_centre,
          :es_cell => TestDummy.create(:es_cell, gene)
        }.merge(attrs)
      )
    end

    setup do
      (1..15).each {|i| Factory.create :gene, :marker_symbol => "Cbx#{i}"}

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

      new_gene_mi(:mi_attempt, 'Cbx5', 'BaSH', 'WTSI')
      new_gene_mi(:mi_attempt, 'Cbx6', 'BaSH', 'WTSI')
      new_gene_mi(:mi_attempt_chimeras_obtained, 'Cbx7', 'BaSH', 'WTSI')
      new_gene_mi(:wtsi_mi_attempt_genotype_confirmed, 'Cbx8', 'BaSH', 'WTSI')
      new_gene_mi(:wtsi_mi_attempt_genotype_confirmed, 'Cbx9', 'BaSH', 'WTSI')
      new_gene_mi(:mi_attempt, 'Cbx10', 'BaSH', 'WTSI', :is_active => false)

      Factory.create :phenotype_attempt,
              :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', 'Cbx11'),
              :mi_attempt => new_gene_mi(:wtsi_mi_attempt_genotype_confirmed, 'Cbx11', 'BaSH', 'WTSI')

      Factory.create :populated_phenotype_attempt,
              :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', 'Cbx12'),
              :mi_attempt => new_gene_mi(:wtsi_mi_attempt_genotype_confirmed, 'Cbx12', 'BaSH', 'WTSI')

      new_gene_mi(:mi_attempt, 'Cbx13', 'JAX', 'JAX')
      new_gene_mi(:mi_attempt, 'Cbx14', 'DTCC', 'UCD')
      new_gene_mi(:mi_attempt, 'Cbx15', 'RIKEN BRC', 'RIKEN BRC')

      Reports::MiProduction::Intermediate.new.cache
    end

    should 'should generate (test column values)' do
      report = Reports::MiProduction::SummaryMonthByMonthActivityImpcIntermediate.new
      mi_hash = report.data['BaSH']['mi_attempt_data'][0]
      pa_hash = report.data['BaSH']['phenotype_data'][0]

      mi_expected = {
        "year"=> Time.now.year,
        "yearspan"=>8,
        "firstrow"=>true,
        "month"=>Time.now.month,
        "consortium"=>"BaSH",
        "es_cell_qc_in_progress"=>1,
        "es_cell_qc_complete"=>2,
        "es_cell_qc_failed"=>1,
        "micro_injection_in_progress"=>8,
        "chimeras_obtained"=>1,
        "genotype_confirmed"=>4,
        "micro_injection_aborted"=>1,
        "cumulative_es_starts"=>1,
        "cumulative_es_complete"=>2,
        "cumulative_es_failed"=>1,
        "cumulative_mis"=>8,
        "cumulative_genotype_confirmed"=>4,
        "mi_goal"=>474,
        "gc_goal"=>164}

      pa_expected = {
        "year"=>Time.now.year,
        "yearspan"=>8,
        "firstrow"=>true,
        "month"=>Time.now.month,
        "consortium"=>"BaSH",
        "phenotype_attempt_registered"=>1,
        "rederivation_started"=>0,
        "rederivation_complete"=>0,
        "cre_excision_started"=>0,
        "cre_excision_complete"=>0,
        "phenotyping_started"=>0,
        "phenotyping_complete"=>1,
        "phenotype_attempt_aborted"=>0,
        "cumulative_phenotype_registered"=>1,
        "cumulative_cre_excision_complete"=>0,
        "cumulative_phenotyping_complete"=>1}


      mi_got = {}
      pa_got = {}

      mi_hash.each do |column_name, column_value|
        mi_got[column_name] = column_value
      end

      pa_hash.each do |column_name, column_value|
        pa_got[column_name] = column_value
      end

      assert_equal mi_expected.keys, mi_got.keys
      assert_equal pa_expected.keys, pa_got.keys

      ['yearspan','firstrow','mi_goal','gc_goal'].each do |col|
        mi_expected.delete(col)
        mi_got.delete(col)
      end

      ['yearspan','firstrow'].each do |col|
        pa_expected.delete(col)
        pa_got.delete(col)
      end
      assert_equal mi_expected, mi_got
      assert_equal pa_expected, pa_got
    end


    should 'show only any consortia' do
      report = Reports::MiProduction::SummaryMonthByMonthActivityImpcIntermediate.new
      assert_equal report.data['BaSH'].nil?, false
      assert_equal report.data['JAX'].nil?, false
      assert_equal report.data['DTCC'].nil?, false
      assert_equal report.data['RIKEN BRC'].nil?, false
    end

    should 'show only komp2 consortia' do
      report = Reports::MiProduction::SummaryMonthByMonthActivityKomp2Compressed.new
      assert_equal report.data['BaSH'].nil?, false
      assert_equal report.data['JAX'].nil?, false
      assert_equal report.data['DTCC'].nil?, false
      assert_equal report.data['RIKEN BRC'].nil?, true
    end


  end
end
