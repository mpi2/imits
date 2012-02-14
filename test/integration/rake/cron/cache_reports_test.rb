require 'test_helper'

module Rake
  module Cron
    class CacheReportsTest < ExternalScriptTestCase
      context 'rake cron:cache_reports' do
        setup do
          Factory.create :user, :email => 'htgt@sanger.ac.uk'
          assert_equal 0, ReportCache.count
        end

        should 'cache intermediate report' do
          Factory.create :phenotype_attempt
          run_script 'rake cron:cache_reports'
          assert_equal 2, ReportCache.where(:name => Reports::MiProduction::Intermediate.report_name).count
        end

        should 'cache summary komp23 report' do
          Factory.create :phenotype_attempt
          run_script 'rake cron:cache_reports'
          assert_equal 2, ReportCache.where(:name => Reports::MiProduction::SummaryKomp23.report_name).count
        end

        should 'cache summary impc3 report' do
          Factory.create :phenotype_attempt
          run_script 'rake cron:cache_reports'
          assert_equal 2, ReportCache.where(:name => Reports::MiProduction::SummaryImpc3.report_name).count
        end

      end
    end
  end
end
