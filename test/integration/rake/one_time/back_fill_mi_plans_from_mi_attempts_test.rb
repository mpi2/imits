# encoding: utf-8

require 'test_helper'

module Rake
  module OneTime
    class BackFillMiPlansFromMiAttemptsTest < ExternalScriptTestCase
      context 'rake one_time:back_fill_mi_plans_from_mi_attempts' do

        should 'work' do
          gene_cbx1 = Factory.create :gene_cbx1
          gene_trafd1 = Factory.create :gene_trafd1
          gene_cbx2 = Factory.create :gene, :marker_symbol => 'Cbx2'
          gene_cbx7 = Factory.create :gene, :marker_symbol => 'Cbx7'

          Factory.create :mi_attempt,
                  :es_cell => Factory.create(:es_cell, :gene => gene_cbx1),
                  :production_centre => Centre.find_by_name!('ICS'),
                  :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC')
          Factory.create :mi_attempt,
                  :es_cell => Factory.create(:es_cell, :gene => gene_trafd1, :pipeline => Pipeline.find_by_name!('KOMP-CSD')),
                  :production_centre => Centre.find_by_name!('WTSI'),
                  :consortium => Consortium.find_by_name!('MGP')
          Factory.create :mi_attempt,
                  :es_cell => Factory.create(:es_cell, :gene => gene_cbx2, :pipeline => Pipeline.find_by_name!('EUCOMM')),
                  :production_centre => Centre.find_by_name!('WTSI'),
                  :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC')
          Factory.create :mi_attempt,
                  :es_cell => Factory.create(:es_cell, :gene => gene_cbx7, :pipeline => Pipeline.find_by_name!('SANGER_FACULTY')),
                  :production_centre => Centre.find_by_name!('WTSI'),
                  :consortium => Consortium.find_by_name!('MGP')

          assert_equal 0, MiPlan.count
          run_script 'rake --trace one_time:back_fill_mi_plans_from_mi_attempts'
          assert_equal 4, MiPlan.count

          mi_plan_eucomm_eumodic_1 = MiPlan.find_by_gene_id!(Gene.find_by_marker_symbol!('Cbx1'))
          mi_plan_mgp_1 = MiPlan.find_by_gene_id!(Gene.find_by_marker_symbol!('Trafd1'))
          mi_plan_eucomm_eumodic_2 = MiPlan.find_by_gene_id!(Gene.find_by_marker_symbol!('Cbx2'))
          mi_plan_mgp_2 = MiPlan.find_by_gene_id!(Gene.find_by_marker_symbol!('Cbx7'))

          assert_equal 'EUCOMM-EUMODIC', mi_plan_eucomm_eumodic_1.consortium.name
          assert_equal 'MGP', mi_plan_mgp_1.consortium.name
          assert_equal 'EUCOMM-EUMODIC', mi_plan_eucomm_eumodic_2.consortium.name
          assert_equal 'MGP', mi_plan_mgp_2.consortium.name

          assert_equal 'ICS', mi_plan_eucomm_eumodic_1.production_centre.name
          assert_equal 'WTSI', mi_plan_mgp_1.production_centre.name
          assert_equal 'WTSI', mi_plan_eucomm_eumodic_2.production_centre.name
          assert_equal 'WTSI', mi_plan_mgp_2.production_centre.name

          assert_equal ['Assigned', 'Assigned', 'Assigned', 'Assigned'],
                  [mi_plan_eucomm_eumodic_1, mi_plan_mgp_1, mi_plan_eucomm_eumodic_2, mi_plan_mgp_2].map {|i| i.mi_plan_status.name}

          assert_equal ['High', 'High', 'High', 'High'],
                  [mi_plan_eucomm_eumodic_1, mi_plan_mgp_1, mi_plan_eucomm_eumodic_2, mi_plan_mgp_2].map {|i| i.mi_plan_priority.name}
        end

        should 'not try to recreate an MiPlan when one with identical attributes already exists' do
          gene_cbx1 = Factory.create :gene_cbx1

          Factory.create :mi_attempt,
                  :es_cell => Factory.create(:es_cell, :gene => gene_cbx1),
                  :production_centre => Centre.find_by_name!('ICS'),
                  :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC')
          Factory.create :mi_attempt,
                  :es_cell => Factory.create(:es_cell, :gene => gene_cbx1),
                  :production_centre => Centre.find_by_name!('ICS'),
                  :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC')

          assert_equal 0, MiPlan.count
          run_script 'rake --trace one_time:back_fill_mi_plans_from_mi_attempts'
          assert_equal 1, MiPlan.count

          mi_plan = MiPlan.first
          assert_equal 'EUCOMM-EUMODIC', mi_plan.consortium.name
          assert_equal gene_cbx1, mi_plan.gene
          assert_equal 'ICS', mi_plan.production_centre.name
        end

      end
    end
  end
end