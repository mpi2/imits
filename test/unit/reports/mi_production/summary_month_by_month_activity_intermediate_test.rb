# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryMonthByMonthActivityIntemediateTest < ActiveSupport::TestCase

  DEBUG = false

  context 'Reports::MiProduction::SummaryMonthByMonthActivityImpcIntemediate' do

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

      Factory.create :populated_phenotype_attempt,
              :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', 'Cbx12'),
              :mi_attempt => new_non_wtsi_gene_gc_mi('Cbx12')

      Reports::MiProduction::Intermediate.new.cache
    end

    should 'generate columns in self.states hash' do
      hash = Reports::MiProduction::SummaryKomp23.generate


      expected = {'ES Cell QC In Progress' =>,
                  'ES Cell QC Complete' =>,
                  'ES Cell QC Failed' =>,
                  'Micro-injection in progress' => ,
                  'Chimeras obtained' => ,
                  'Genotype confirmed' => ,
                  'Micro-injection aborted' => ,
                  'Phenotype Attempt Registered' =>,
                  'Rederivation Started' =>,
                  'Rederivation Complete' => ,
                  'Cre Excision Started' => ,
                  'Cre Excision Complete' => ,
                  'Phenotyping Started' => ,
                  'Phenotyping Complete' =>,
                  'Phenotype Attempt Aborted' =>
                 }


      got = {}

      hash['BaSH'][2012][6]['BaSH'].each do |column_name, value|
        got[column_name] = value
      end

      assert_equal expected, got
    end

    should 'generate columns in self.states hash' do
      generated = Reports::MiProduction::SummaryKomp23.generate
      hash = self.class.format(generated)
      expected = {}
      expected['mi_attempt'] = {

            'year' => ,
            'yearspan' => ,
            'firstrow' =>,
            'month' => ,
            'consortium' => ,
            'assigned_date' => ,
            'es_cell_qc_in_progress' => ,
            'es_cell_qc_complete' => ,
            'es_cell_qc_failed' => ,
            'micro_injection_in_progress' => ,
            'chimeras_obtained' => ,
            'genotype_confirmed' => ,
            'micro_injection_aborted' => ,
            'cummulative_assigned_date' => ,
            'cumulative_es_starts' => ,
            'cumulative_es_complete' => ,
            'cumulative_es_failed' => ,
            'cumulative_mis' => ,
            'cumulative_genotype_confirmed' => ,
            'mi_goal' => ,
            'gc_goal' => ,
            }

      expected['phenotype_attempt'] = {
            'year' =>,
            'yearspan' =>,
            'firstrow' =>,
            'month' =>,
            'consortium' =>,
            'phenotype_attempt_registered' => ,
            'rederivation_started' =>,
            'rederivation_complete' =>,
            'cre_excision_started' =>,
            'cre_excision_complete' =>,
            'phenotyping_started' =>,
            'phenotyping_complete' =>,
            'phenotype_attempt_aborted' =>,
            'cumulative_phenotype_registered' =>,
            'cumulative_cre_excision_complete' =>,
            'cumulative_phenotyping_complete' =>,
        }

      got = {}

      hash['BaSH'].each do |column_name, value|
        got[column_name] = value
      end

      assert_equal expected['mi_attempt'], got['mi_attempt']
      assert_equal expected['phenotype'], got['phenotype']
    end


    should 'generate csv' do
      generated = Reports::MiProduction::SummaryKomp23.new
      expected = {}
      expected['headers'] = ['Date','Year','Month', 'Consortium', 'Cumulative ES Starts', 'ES Cell QC In Progress', 'ES Cell QC Complete', 'ES Cell QC Failed', 'Micro-Injection In Progress', 'Cumulative MIs', 'MI Goal', 'Chimeras obtained' , 'Genotype confirmed', 'Cumulative Genotype Confirmed', 'GC Goal','Micro-injection aborted', 'Phenotype Attempt Registered', 'Rederivation Started', 'Rederivation Complete', 'Cre Excision Started', 'Cre Excision Complete', 'Phenotyping Started', 'Phenotyping Complete', 'Phenotype Attempt Aborted']
      expected['data'] = []

      got = {}

      data generated.split('\n')
      got['headers'] = data[0].split(',')
      got['data'] = data[1].split(',')
      end

      assert_equal expected['headers'], got['headers']
      assert_equal expected['data'], got['data']
    end


end