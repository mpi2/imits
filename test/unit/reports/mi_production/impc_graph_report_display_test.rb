# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::ImpcGraphReportDisplayTest < ActiveSupport::TestCase

  context 'Reports::MiProduction::ImpcGraphReportDisplay' do

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

      Factory.create :phenotype_attempt_status_pdc,
              :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', 'Cbx12'),
              :mi_attempt => new_gene_mi(:wtsi_mi_attempt_genotype_confirmed, 'Cbx12', 'BaSH', 'WTSI')

      new_gene_mi(:mi_attempt, 'Cbx13', 'JAX', 'JAX')
      new_gene_mi(:mi_attempt, 'Cbx14', 'DTCC', 'UCD')
      new_gene_mi(:mi_attempt, 'Cbx15', 'RIKEN BRC', 'RIKEN BRC')
      mi_plan = MiPlan.all
      mi_plan.each do |plan|
        status = plan.status_stamps
        status.each do |stamp|
          stamp.update_attributes(:created_at => 1.month.ago)
        end
      end

      mi_attempt = MiAttempt.all
      mi_attempt.each do |mi|
        status = mi.status_stamps
        status.each do |stamp|
          stamp.update_attributes(:created_at => 1.month.ago)
        end
      end

      phenotype_attempt = PhenotypeAttempt.all
      phenotype_attempt.each do |phen|
        status = phen.status_stamps
        status.each do |stamp|
          stamp.update_attributes(:created_at => 1.month.ago)
        end
      end

      Reports::MiProduction::Intermediate.new.cache
    end

    should 'should generate (test column values)' do
      report = Reports::MiProduction::ImpcGraphReportDisplay.new
      hash = report.graph['BaSH']['tabulate'][0]
      expected = {
        "assigned_genes" => 12,
        "es_qc" => 4,
        "es_qc_confirmed" => 2,
        "es_qc_failed" => 1,
        "mouse_production" => 8,
        "confirmed_mice" => 4,
        "intent_to_phenotype" => 2,
        "cre_excision_complete" => 1,
        "phenotyping_complete" => 1}
      got = {}

      hash.each do |column_name, column_value|
        got[column_name] = column_value
      end

      assert_equal expected.keys, got.keys
      assert_equal expected, got
    end

    should 'show only komp2 consortia' do
      report = Reports::MiProduction::ImpcGraphReportDisplay.new
      assert_equal report.data['BaSH'].nil?, false
      assert_equal report.data['JAX'].nil?, false
      assert_equal report.data['DTCC'].nil?, false
      assert_equal report.data['RIKEN BRC'].nil?, true
    end

    should 'create graphs' do
      report = Reports::MiProduction::ImpcGraphReportDisplay.new
      assert_equal report.chart_file_names.empty?, false
    end
  end
end
