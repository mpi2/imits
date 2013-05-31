# encoding: utf-8

require 'test_helper'

class TrackingGoalTest < ActiveSupport::TestCase

  context 'TrackingGoal' do

    should 'edit an already set date' do
      goal = Factory(:tracking_goal)
      goal.month = 3 #March
      goal.year = 2013

      assert_true goal.save
      assert_equal 3, goal.month
      assert_equal 2013, goal.year
      assert_equal Date.parse('2013-03-01'), goal.date
    end

    should 'set a cumulative date and then modify it to a specific date' do
      goal = Factory.build(:tracking_goal)

      goal.month = nil
      goal.year = nil

      assert_true goal.save
      assert_true goal.cumulative?

      goal.month = 3 #March
      goal.year = 2013

      assert_true goal.save
      assert_false goal.cumulative?
      assert_equal 3, goal.month
      assert_equal 2013, goal.year
      assert_equal Date.parse('2013-03-01'), goal.date
    end

  end
end
