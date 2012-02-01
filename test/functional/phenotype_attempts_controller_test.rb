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
    end

  end
end
