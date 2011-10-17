# encoding: utf-8

require 'test_helper'

class Rake::OneTimeTest < ExternalScriptTestCase
  context 'rake one_time:' do

    context 'fix_status_stamps' do
      should 'work for MIs created < 2011-10-10 10:30 +0100' do
        creation_time = Time.parse('2011-10-10T10:29:59+0100')
        mi_date = Date.parse('2010-10-04')
        mi = Factory.create :mi_attempt,
                :created_at => creation_time, :mi_date => mi_date
        sleep 1                                            # [0] in progress
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

        assert_operator mi.created_at, :<, Time.parse('2011-10-10 10:30 +0100')

        output = run_script "rake --trace one_time:fix_back_filled_status_stamps"
        assert !output.match('aborted'), output

        mi.reload

        assert_equal mi.mi_date.to_time, mi.status_stamps.first.created_at
      end

      should 'not touch MIs created >= 2011-10-10 10:30 +0100' do
        mi = Factory.create :mi_attempt,
                :mi_date => Date.parse('2010-01-01')

        status_stamp_time = mi.status_stamps.first.created_at

        output = run_script 'rake --trace one_time:fix_back_filled_status_stamps'
        assert !output.match('aborted'), output

        mi.reload
        assert_equal status_stamp_time, mi.status_stamps.first.created_at
      end
    end

  end
end
