# encoding: utf-8

require 'test_helper'

class BackFillMiAttemptStatusStampsTest < ExternalScriptTestCase
  context 'rake one_time:back_fill_mi_attempt_status_stamps' do

    should 'create all status stamps for MiAttempt, using created_at for first one' do
      mi = Factory.create :mi_attempt, :mi_date => nil   # [0] in progress
      sleep 0.5
      mi.update_attributes!(:total_female_chimeras => 4) # [1] no change
      sleep 0.5
      set_mi_attempt_genotype_confirmed(mi)              # [2] genotype confirmed
      sleep 0.5
      mi.update_attributes!(:total_female_chimeras => 2) # [3] no change
      sleep 0.5
      mi.update_attributes!(:is_active => false)         # [4] aborted
      sleep 0.5
      mi.update_attributes!(:total_male_chimeras => 5)   # [5] no change
      sleep 0.5
      mi.update_attributes!(:is_active => true)          # [6] genotype confirmed
      sleep 0.5
      mi.update_attributes!(:total_male_chimeras => 1)   # [7] no change

      mi.status_stamps.destroy_all

      output = run_script "rake --trace one_time:back_fill_mi_attempt_status_stamps"
      assert !output.match('aborted'), output

      mi.reload

      assert_equal [mi.audits[0].created_at.to_s, MiAttemptStatus.micro_injection_in_progress],
              [mi.status_stamps[0].created_at.to_s, mi.status_stamps[0].mi_attempt_status]
    end

  end
end
