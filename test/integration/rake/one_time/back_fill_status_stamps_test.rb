# encoding: utf-8

require 'test_helper'

class BackFillMiAttemptStatusStampsTest < ExternalScriptTestCase
  context 'rake one_time:back_fill_mi_attempt_status_stamps' do

    should 'create all status stamps for MiAttempt, using created_at for first one' do
      mi = Factory.create :mi_attempt                    # [0] in progress
      sleep 1
      mi.update_attributes!(:total_female_chimeras => 4) # [1] no change
      sleep 1
      set_mi_attempt_genotype_confirmed(mi)              # [2] genotype confirmed
      sleep 1
      mi.update_attributes!(:total_female_chimeras => 2) # [3] no change
      sleep 1
      mi.update_attributes!(:is_active => false)         # [4] aborted
      sleep 1
      mi.update_attributes!(:total_male_chimeras => 5)   # [5] no change
      sleep 1
      mi.update_attributes!(:is_active => true)          # [6] genotype confirmed
      sleep 1
      mi.update_attributes!(:total_male_chimeras => 1)   # [7] no change

      mi.status_stamps.destroy_all

      output = run_script "rake --trace one_time:back_fill_status_stamps"
      assert !output.match('aborted'), output

      mi.reload

      assert_equal [mi.audits[0].revision.created_at.to_s, MiAttemptStatus.micro_injection_in_progress],
              [mi.status_stamps[0].created_at.to_s, mi.status_stamps[0].mi_attempt_status]

      assert_equal [mi.audits[2].revision.created_at.to_s, MiAttemptStatus.genotype_confirmed],
              [mi.status_stamps[1].created_at.to_s, mi.status_stamps[1].mi_attempt_status]

      assert_equal [mi.audits[4].revision.created_at.to_s, MiAttemptStatus.micro_injection_aborted],
              [mi.status_stamps[2].created_at.to_s, mi.status_stamps[2].mi_attempt_status]

      assert_equal [mi.audits[6].revision.created_at.to_s, MiAttemptStatus.genotype_confirmed],
              [mi.status_stamps[3].created_at.to_s, mi.status_stamps[3].mi_attempt_status]

      assert_equal 4, mi.status_stamps.size
    end

    should 'create Assigned status stamp for MiPlan set to earliest mi_date of its attempts' do
      gene = Factory.create :gene, :marker_symbol => 'Zz99'

      mi_plan = Factory.create :mi_plan, :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'), :gene => gene

      es_cell_1 = Factory.create :es_cell, :gene => gene, :name => 'EPD_9999_Z_01'
      es_cell_2 = Factory.create :es_cell, :gene => gene, :name => 'EPD_9999_Z_02'

      mi = Factory.create :mi_attempt, :mi_date => Time.parse('2011-07-22T12:00:01 UTC'),
              :es_cell => es_cell_1, :production_centre_name => 'WTSI',
              :consortium_name => 'BaSH'

      mi = Factory.create :mi_attempt, :mi_date => Time.parse('2011-05-22T12:00:01 UTC'),
              :es_cell => es_cell_1, :production_centre_name => 'WTSI',
              :consortium_name => 'BaSH'

      Factory.create :mi_attempt, :mi_date => Time.parse('2011-08-13T12:00:01 UTC'),
              :es_cell => es_cell_2, :production_centre_name => 'WTSI',
              :consortium_name => 'BaSH'

      Factory.create :mi_attempt, :mi_date => nil,
              :es_cell => es_cell_2, :production_centre_name => 'WTSI',
              :consortium_name => 'BaSH'

      mi_plan.reload
      assert_equal 4, mi_plan.mi_attempts.size

      mi_plan.status_stamps.destroy_all

      output = run_script "rake --trace one_time:back_fill_status_stamps"
      assert !output.match('aborted'), output

      mi.reload
      mi_plan.reload

      assert_equal 1, mi_plan.status_stamps.size
      assert_equal MiPlanStatus[:Assigned], mi_plan.status_stamps[0].mi_plan_status
      assert_equal Time.parse('2011-05-22T00:00:00 UTC').to_s, mi_plan.status_stamps[0].created_at.to_s
    end

    should 'create Assigned status stamp for MiPlan set to earliest created_at of its attempts' do
      gene = Factory.create :gene, :marker_symbol => 'Zz99'

      mi_plan = Factory.create :mi_plan, :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'), :gene => gene

      es_cell_1 = Factory.create :es_cell, :gene => gene, :name => 'EPD_9999_Z_01'
      es_cell_2 = Factory.create :es_cell, :gene => gene, :name => 'EPD_9999_Z_02'

      mi = Factory.create :mi_attempt, :mi_date => Time.parse('2011-07-22T12:00:01 UTC'),
              :es_cell => es_cell_1, :production_centre_name => 'WTSI',
              :consortium_name => 'BaSH'

      mi = Factory.create :mi_attempt, :created_at => Time.parse('2011-05-22T12:00:01 UTC'),
              :es_cell => es_cell_1, :production_centre_name => 'WTSI',
              :consortium_name => 'BaSH'

      Factory.create :mi_attempt, :mi_date => Time.parse('2011-08-13T12:00:01 UTC'),
              :es_cell => es_cell_2, :production_centre_name => 'WTSI',
              :consortium_name => 'BaSH'

      Factory.create :mi_attempt, :mi_date => nil,
              :es_cell => es_cell_2, :production_centre_name => 'WTSI',
              :consortium_name => 'BaSH'

      mi_plan.reload
      assert_equal 4, mi_plan.mi_attempts.size

      mi_plan.status_stamps.destroy_all

      output = run_script "rake --trace one_time:back_fill_status_stamps"
      assert !output.match('aborted'), output

      mi.reload
      mi_plan.reload

      assert_equal 1, mi_plan.status_stamps.size
      assert_equal MiPlanStatus[:Assigned], mi_plan.status_stamps[0].mi_plan_status
      assert_equal mi.created_at.to_s, mi_plan.status_stamps[0].created_at.to_s
    end

  end
end
