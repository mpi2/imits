# encoding: utf-8

require 'test_helper'

class ProductionGoalsControllerTest < ActionController::TestCase
  context 'ProductionGoalsController' do

    should 'require authentication' do
      get :index
      assert_false response.success?
      assert_redirected_to new_user_session_path
    end

    context 'when authenticated' do
      setup do
        sign_in default_user
      end

      should 'create a production goal via POST request (via JSON)' do
        assert_difference('ProductionGoal.count') do
          post :create,
            :production_goal => {
              'consortium_id' => Consortium.first.id,
              'year' => 2014,
              'month' => 1,
              'mi_goal' => 55,
              'gc_goal' => 44
            }, :format => 'json'
        end

        assert_response :success 
      end

      should 'create duplicate production goals and fail (via JSON)' do

        production_goal = Factory.create(:production_goal)

        post :create,
          :production_goal => {
            'consortium_id' => production_goal.consortium.id,
            'year' => production_goal.year,
            'month' => production_goal.month,
            'mi_goal' => 55,
            'gc_goal' => 44
          }, :format => 'json'

        assert_equal JSON.parse(response.body), {'error' => 'Could not create production goal (invalid data)'}
        assert_response 422

      end

      should 'fail to create a production goal via POST request (via JSON) if year is invalid' do

        post :create,
          :production_goal => {
            'consortium_id' => Consortium.first.id,
            'year' => 2055,
            'month' => 1,
            'mi_goal' => 55,
            'gc_goal' => 44
          }, :format => 'json'

        assert_equal JSON.parse(response.body), {'error' => 'Could not create production goal (invalid data)'}
        assert_response 422

      end

      should 'destroy a production centre (via JSON)' do
        production_goal = Factory.create(:production_goal)
        delete :destroy, 'id' => production_goal.id
        assert_response :success
      end

      should 'destroy a production centre (via JSON)' do
        production_goal = Factory.create(:production_goal)
        put :update, 'id' => production_goal.id,
        :production_goal => {
          'year' => 2014
        }, :format => 'json'

        assert_response :success
      end
    end
  end
end