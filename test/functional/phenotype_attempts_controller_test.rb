require 'test_helper'

class PhenotypeAttemptsControllerTest < ActionController::TestCase
  context 'PhenotypeAttemptsController' do

    should 'require authentication' do
      pt = Factory.create :phenotype_attempt
      get :show, :id => pt.id, :format => :json
      assert_false response.success?
    end

    context 'when authenticated' do
      setup do
        sign_in default_user
      end

      context 'GET show' do
        should 'work for JSON' do
          pt = Factory.create(:phenotype_attempt).to_public
          get :show, :id => pt.id, :format => :json
          assert response.success?
          assert_equal pt.to_json, response.body
        end
      end

      context 'POST create' do
        should 'work for JSON' do
          assert_equal 0, PhenotypeAttempt.count
          mi = Factory.create :mi_attempt_genotype_confirmed

          attributes = {
            :mi_attempt_colony_name => mi.colony_name
          }
          post :create, :phenotype_attempt => attributes, :format => :json
          assert_response :success, response.body

          pt = PhenotypeAttempt.first.to_public
          assert_equal pt.to_json, response.body
        end

        should 'fail properly for JSON' do
          mi = Factory.create :mi_attempt

          attributes = {
            :mi_attempt_colony_name => mi.colony_name
          }
          post :create, :phenotype_attempt => attributes, :format => :json
          assert_response 422, response.body
        end
      end

      context 'PUT update' do
        should 'work for JSON' do
          pt = Factory.create(:phenotype_attempt).to_public
          assert pt.is_active?
          put :update, :id => pt.id, :phenotype_attempt => {:is_active => false},
                  :format => :json
          assert_response :success

          pt.reload; assert_equal false, pt.is_active?
        end

        should 'fail properly for JSON' do
          pt = Factory.create(:phenotype_attempt).to_public
          assert pt.is_active?
          put :update, :id => pt.id, :phenotype_attempt => {:consortium_name => 'Nonexistent'},
                  :format => :json
          assert_response 422
        end
      end

    end # when authenticated

  end
end
