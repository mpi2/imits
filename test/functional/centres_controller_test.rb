# encoding: utf-8

require 'test_helper'

class CentresControllerTest < ActionController::TestCase
  context 'CentresController' do

    should 'require authentication' do
      get :index
      assert_false response.success?
      assert_redirected_to new_user_session_path
    end

    context 'when authenticated' do
      setup do
        sign_in default_user
      end

      should 'work (via JSON)' do
        get :index, :format => :json
        data = JSON.parse(response.body)
        assert_response :success 
        assert_equal 17, data.size
      end

      should 'create a centre via POST request (via JSON)' do
        post :create,
          :centre => {'name' => "New centre"},
          :format => 'json'

        new_centre = Centre.find_by_name("New centre")

        assert !new_centre.blank?
        assert_response :success 
      end

      should 'create an invalid centre via POST request (via JSON)' do
        post :create,
          :centre => {'name' => "WTSI"},
          :format => 'json'

        assert_equal JSON.parse(response.body), {'error' => 'Centre name must be present and unique.'}
        assert_response 422
      end

      should 'create and then update via a POST, then a PUT request (via JSON)' do
        post :create,
          :centre => {'name' => "New centre"},
          :format => 'json'

        new_centre = Centre.find_by_name("New centre")

        put :update,
          :id => new_centre.id,
          :centre => {'name' => "Newer centre"},
          :format => 'json'

        new_centre.reload
        assert_equal 'Newer centre', new_centre.name
        assert_response :success
      end

      should 'create and then destroy via a POST, then a DELETE request (via JSON)' do
        post :create,
          :centre => {'name' => "New centre"},
          :format => 'json'

        new_centre = Centre.find_by_name("New centre")

        delete :destroy,
          :id => new_centre.id

        assert Centre.find_by_id(new_centre.id).blank?
        assert_response :success
      end

    end
  end
end

