# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::LanguishingTest < ActiveSupport::TestCase
  Languishing = Reports::MiProduction::Languishing

  context 'Reports::MiProduction::Languishing' do

    def bash; @consortium_bash ||= Consortium.find_by_name! 'BaSH'; end
    def wtsi; @centre_wtsi ||= Centre.find_by_name! 'WTSI'; end
    def cbx1; @gene_cbx1 ||= Factory.create :gene_cbx1; end

    should 'count latency from MiPlans without any attempts on them' do
      bash_plan1 = Factory.create :mi_plan,
              :consortium => bash,
              :status => MiPlan::Status['Assigned']
      assert_equal 'Assigned', bash_plan1.status.name
      replace_status_stamps bash_plan1,
              'Assigned' => 2.months.ago.utc + 5.days

      bash_plan2 = Factory.create :mi_plan,
              :consortium => bash,
              :status => MiPlan::Status['Assigned']
      assert_equal 'Assigned', bash_plan2.status.name
      replace_status_stamps bash_plan2,
              'Assigned' => 2.months.ago.utc + 15.days

      bash_plan3 = Factory.create :mi_plan,
              :consortium => bash,
              :status => MiPlan::Status['Assigned']
      assert_equal 'Assigned', bash_plan3.status.name
      replace_status_stamps bash_plan3,
              'Assigned' => 15.days.ago.utc

      Reports::MiProduction::Intermediate.new.cache
      grouping = Reports::MiProduction::Languishing.generate(:consortia => 'BaSH')
      group = grouping['BaSH']

      assigned_row = group.find {|r| r[0] == 'Assigned'}
      assert_equal 1, assigned_row['0 months']
      assert_equal 2, assigned_row['1 month']
    end

    context '::latency_in_months' do
      should 'be 0 when date less than 30 days ' do
        date_this_month = Date.today - 29.days
        assert_equal 0, Languishing.latency_in_months(date_this_month)
      end

      should 'be 1 when date is 30 or more days ago' do
        date_last_month = Date.today - 30.days
        assert_equal 1, Languishing.latency_in_months(date_last_month)
      end

      should 'be 2 when date is more 60 or more days ago' do
        date_last_month = Date.today - 60.days
        assert_equal 2, Languishing.latency_in_months(date_last_month)
      end

      should 'convert strings to date' do
        date_last_month = (Date.today - 30.days).to_s
        assert_equal 1, Languishing.latency_in_months(date_last_month)
      end
    end

  end
end
