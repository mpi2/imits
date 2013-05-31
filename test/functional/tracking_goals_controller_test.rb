# encoding: utf-8

require 'test_helper'

class TrackingGoalsControllerTest < ActionController::TestCase
  context 'TrackingGoalsController' do

    should 'require authentication' do
      get :index
      assert_false response.success?
      assert_redirected_to new_user_session_path
    end

    context 'when authenticated' do
      setup do
        sign_in default_user
      end

      should 'create a tracking goal via POST request (via JSON)' do
        assert_difference('TrackingGoal.count') do
          tracking_goal = Factory.build(:tracking_goal)

          post :create,
            :tracking_goal => {
              'production_centre_name' => tracking_goal.production_centre_name,
              'year' => tracking_goal.year,
              'month' => tracking_goal.month,
              'goal_type' => tracking_goal.goal_type,
              'goal' => tracking_goal.goal
            }, :format => 'json'
        end

        assert_response :success 
      end

      should 'create duplicate tracking goals and fail (via JSON)' do

        tracking_goal = Factory.build(:tracking_goal)
        tracking_goal.year = 2013
        tracking_goal.month = 3

        tracking_goal.save!

        assert_equal Date.parse('2013-03-01'), tracking_goal.date

        post :create,
          :tracking_goal => {
            'production_centre_name' => tracking_goal.production_centre.name,
            'year' => tracking_goal.year,
            'month' => tracking_goal.month,
            'goal_type' => tracking_goal.goal_type,
            'goal' => tracking_goal.goal
          }, :format => 'json'

        expected = {
          'error' => 'Could not create tracking goal (invalid data)'
        }

        assert_equal expected, JSON.parse(response.body)
        assert_response 422

      end

      should 'destroy a tracking goal (via JSON)' do
        tracking_goal = Factory.create(:tracking_goal)
        tracking_goal.year = 2013
        tracking_goal.month = 3

        delete :destroy, 'id' => tracking_goal.id, :format => 'json'

        assert_response :success
      end

      should 'update a tracking goal (via JSON)' do
        tracking_goal = Factory.build(:tracking_goal)
        tracking_goal.year = 2013
        tracking_goal.month = 3
        tracking_goal.save!

        put :update, 'id' => tracking_goal.id,
        :tracking_goal => {
          'year' => 2014
        }, :format => 'json'

        assert_equal 2014, TrackingGoal.find(tracking_goal.id).year
        assert_response :success
      end
    end
  end
end