require 'test_helper'

module Rake
  module Cron
    class SyncMiAttemptInProgressDatesTest < Kermits2::ExternalScriptTestCase
      context 'rake cron:sync_mi_attempt_in_progress_dates' do

        should 'work' do
          Factory.create :user, :email => 'htgt@sanger.ac.uk'

          mi1 = Factory.create :mi_attempt_genotype_confirmed,
                  :mi_date => '2011-11-01'
          replace_status_stamps(mi1,
            [
              ['Micro-injection in progress', '2011-12-01 00:00 UTC'],
              ['Genotype confirmed', '2011-12-02 00:00 UTC']
            ]
          )

          mi2 = Factory.create :mi_attempt, :is_active => false,
                  :mi_date => '2011-11-02'
          replace_status_stamps(mi2,
            [
              ['Genotype confirmed', '2011-12-02 00:00 UTC'],
              ['Micro-injection in progress', '2011-12-03 00:00 UTC'],
              ['Micro-injection aborted', '2011-12-04 00:00 UTC']
            ]
          )

          run_script 'rake cron:sync_mi_attempt_in_progress_dates'
          sleep 3
          mi1.reload
          mi2.reload

          assert_equal '2011-11-01', mi1.in_progress_date.to_s
          assert_equal '2011-11-02', mi2.in_progress_date.to_s
        end

      end
    end
  end
end
