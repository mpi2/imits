# encoding: utf-8

require 'test_helper'

module Rake
  module OneTime
    class BackFillMiPlansFromMiAttemptsTest < ExternalScriptTestCase
      context 'rake one_time:back_fill_mi_plans_from_mi_attempts' do

        should 'work' do
          gene_cbx1 = Factory.create :gene_cbx1
          gene_trafd1 = Factory.create :gene_trafd1
          gene_cbx2 = Factory.create :gene, :marker_symbol => 'Cbx2', :mgi_accession_id => 'MGI:88289'

          Factory.create :mi_attempt,
                  :es_cell => Factory.create(:es_cell, :gene => gene_cbx1),
                  :production_centre => Centre.find_by_name!('ICS')
          Factory.create :mi_attempt,
                  :es_cell => Factory.create(:es_cell, :gene => gene_trafd1, :pipeline => Pipeline.find_by_name!('KOMP-CSD')),
                  :production_centre => Centre.find_by_name!('WTSI')
          Factory.create :mi_attempt,
                  :es_cell => Factory.create(:es_cell, :gene => gene_cbx2, :pipeline => Pipeline.find_by_name!('EUCOMM')),
                  :production_centre => Centre.find_by_name!('WTSI')

          assert_equal 0, MiPlan.count
          run_script 'rake --trace one_time:back_fill_mi_plans_from_mi_attempts'
          assert_equal 3, MiPlan.count

          mi_plan_eucomm_eumodic_1 = MiPlan.find_by_gene_id!(Gene.find_by_marker_symbol!('Cbx1'))
          mi_plan_mgp = MiPlan.find_by_gene_id!(Gene.find_by_marker_symbol!('Trafd1'))
          mi_plan_eucomm_eumodic_2 = MiPlan.find_by_gene_id!(Gene.find_by_marker_symbol!('Cbx2'))

          assert_equal 'EUCOMM-EUMODIC', mi_plan_eucomm_eumodic_1.consortium.name
          assert_equal 'MGP', mi_plan_mgp.consortium.name
          assert_equal 'EUCOMM-EUMODIC', mi_plan_eucomm_eumodic_2.consortium.name

          assert_equal 'ICS', mi_plan_eucomm_eumodic_1.production_centre.name
          assert_equal 'WTSI', mi_plan_mgp.production_centre.name
          assert_equal 'WTSI', mi_plan_eucomm_eumodic_2.production_centre.name

          assert_equal ['Assigned', 'Assigned', 'Assigned'],
                  [mi_plan_eucomm_eumodic_1.mi_plan_status.name, mi_plan_mgp.mi_plan_status.name, mi_plan_eucomm_eumodic_2.mi_plan_status.name]

          assert_equal ['High', 'High', 'High'],
                  [mi_plan_eucomm_eumodic_1.mi_plan_priority.name, mi_plan_mgp.mi_plan_priority.name, mi_plan_eucomm_eumodic_2.mi_plan_priority.name]
        end

      end
    end
  end
end