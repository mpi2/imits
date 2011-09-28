# encoding: utf-8

require 'test_helper'

class BackFillMiAttemptStatusStampsTest < ExternalScriptTestCase
  context 'rake one_time:back_fill_mi_attempt_status_stamps' do

    should 'create all status stamps for MiAttempt, using created_at for first one' do
      mi = Factory.create :mi_attempt, :mi_date => nil   # [0] in progress
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

      output = run_script "rake --trace one_time:back_fill_mi_attempt_status_stamps"
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

    should 'create all status stamps for MiAttempt, using mi_date for first one' do
      mi_date = Time.parse('2011-07-22T12:00:01 UTC')

      mi = Factory.create :mi_attempt, :mi_date => mi_date
                                                         # [0] in progress
      sleep 1
      mi.update_attributes!(:total_female_chimeras => 4) # [1] no change
      sleep 1
      set_mi_attempt_genotype_confirmed(mi)              # [2] genotype confirmed

      mi.status_stamps.destroy_all

      output = run_script "rake --trace one_time:back_fill_mi_attempt_status_stamps"
      assert !output.match('aborted'), output

      mi.reload

      assert_equal [mi_date.to_s, MiAttemptStatus.micro_injection_in_progress],
              [mi.status_stamps[0].created_at.to_s, mi.status_stamps[0].mi_attempt_status]

      assert_equal [mi.audits[2].revision.created_at.to_s, MiAttemptStatus.genotype_confirmed],
              [mi.status_stamps[1].created_at.to_s, mi.status_stamps[1].mi_attempt_status]

      assert_equal 2, mi.status_stamps.size
    end

  end
end
