# encoding: utf-8

require 'test_helper'

class MiPlan::AggregatedViewTest < ActiveSupport::TestCase
  context 'MiPlan::AggregatedView' do

    should belong_to :latest_mi_plan_status

    should 'search against the view, not the table' do
      plan = Factory.create :mi_plan
      plan.update_attributes!(:mi_plan_status => MiPlanStatus[:Conflict])
      plan.update_attributes!(:mi_plan_status => MiPlanStatus[:Assigned])
      plans = MiPlan::AggregatedView.search(:latest_mi_plan_status_name_eq => 'Assigned').result
      assert_equal [plan.id], plans.map(&:id)
    end

  end
end
