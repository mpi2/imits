# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryMonthByMonthActivityImpcIntermediateTest < ActiveSupport::TestCase

  context 'Reports::MiProduction::SummaryMonthByMonthActivityImpcIntermediate' do

    def new_gene_mi(factory, gene, consortia, production_centre, attrs = {})
      plan = TestDummy.mi_plan(consortia, production_centre, gene, :force_assignment => true)
      return Factory.create(factory, {
          :mi_plan => plan,
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

      new_gene_mi(:mi_attempt2, 'Cbx5', 'BaSH', 'WTSI')
      new_gene_mi(:mi_attempt2, 'Cbx6', 'BaSH', 'WTSI')
      new_gene_mi(:mi_attempt2_status_chr, 'Cbx7', 'BaSH', 'WTSI')
      new_gene_mi(:mi_attempt2_status_gtc, 'Cbx8', 'BaSH', 'WTSI')
      new_gene_mi(:mi_attempt2_status_gtc, 'Cbx9', 'BaSH', 'WTSI')
      new_gene_mi(:mi_attempt2, 'Cbx10', 'BaSH', 'WTSI', :is_active => false)

      Factory.create :phenotype_attempt,
              :mi_attempt => new_gene_mi(:mi_attempt2_status_gtc, 'Cbx11', 'BaSH', 'WTSI')

      Factory.create :phenotype_attempt_status_pdc,
              :mi_attempt => new_gene_mi(:mi_attempt2_status_gtc, 'Cbx12', 'BaSH', 'WTSI')

      new_gene_mi(:mi_attempt2, 'Cbx13', 'JAX', 'JAX')
      new_gene_mi(:mi_attempt2, 'Cbx14', 'DTCC', 'UCD')
      new_gene_mi(:mi_attempt2, 'Cbx15', 'RIKEN BRC', 'RIKEN BRC')

      Reports::MiProduction::Intermediate.new.cache
    end

    should 'generate test column values' do
      report = Reports::MiProduction::SummaryMonthByMonthActivityImpcIntermediate.new
      mi_hash = report.data['BaSH']['mi_attempt_data'][0]
      pa_hash = report.data['BaSH']['phenotype_data'][0]

      mi_expected = {
        "year"=> Time.now.year,
        "yearspan"=>8,
        "firstrow"=>true,
        "month"=>Time.now.month,
        "consortium"=>"BaSH",
        "es_cell_qc_in_progress"=>4,
        "es_cell_qc_complete"=>2,
        "es_cell_qc_failed"=>1,
        "micro_injection_in_progress"=>8,
        "chimeras_obtained"=>5,
        "genotype_confirmed"=>4,
        "micro_injection_aborted"=>1,
        "cumulative_es_starts"=>4,
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
        "phenotype_attempt_registered"=>2,
        "rederivation_started"=>1,
        "rederivation_complete"=>1,
        "cre_excision_started"=>1,
        "cre_excision_complete"=>1,
        "phenotyping_started"=>1,
        "phenotyping_complete"=>1,
        "phenotype_attempt_aborted"=>0,
        "cumulative_phenotype_registered"=>2,
        "cumulative_cre_excision_complete"=>1,
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

    should 'not fall over if there exists a status stamp with a date set in the future.' do
      mi_attempt = MiAttempt.first
      status_stamp = mi_attempt.status_stamps.first
      status_stamp.created_at = Time.now.next_month
      status_stamp.save!
      Reports::MiProduction::Intermediate.new.cache
      report = Reports::MiProduction::SummaryMonthByMonthActivityKomp2Compressed
      assert_nothing_raised {report.generate}
    end

  end
end
