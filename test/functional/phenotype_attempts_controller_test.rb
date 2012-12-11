require 'test_helper'

class PhenotypeAttemptsControllerTest < ActionController::TestCase
  context 'PhenotypeAttemptsController' do

    should 'require authentication' do
      pt = Factory.create :phenotype_attempt
      get :show, :id => pt.id, :format => :json
      assert ! response.success?
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
          mi = Factory.create :mi_attempt2_status_gtc

          attributes = {
            :mi_attempt_colony_name => mi.colony_name
          }
          post :create, :phenotype_attempt => attributes, :format => :json
          assert_response :success, response.body

          pt = PhenotypeAttempt.first.to_public
          assert_equal pt.to_json, response.body
        end

        should 'fail properly for JSON' do
          mi = Factory.create :mi_attempt2

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

      context 'GET index' do
        should 'allow filtering with Ransack' do
          pt = Factory.create :phenotype_attempt, :deleter_strain_id => DeleterStrain.first,
                  :colony_name => 'A'
          Factory.create :phenotype_attempt, :deleter_strain_id => nil,
                  :colony_name => 'B'

          get :index, :deleter_strain_name_eq => DeleterStrain.first.name, :format => :json
          assert response.success?
          assert_equal ['A'], JSON.parse(response.body).map {|i| i['colony_name'] }
        end

        should 'allow sorting' do
          Factory.create :phenotype_attempt, :colony_name => 'C'
          Factory.create :phenotype_attempt, :colony_name => 'A'
          Factory.create :phenotype_attempt, :colony_name => 'B'
          get :index, :format => :json, :sorts => 'colony_name asc'
          assert_equal ['A', 'B', 'C'], JSON.parse(response.body).map{|i| i['colony_name']}
        end

        should 'translate search params' do
          cbx1 = Factory.create :gene_cbx1
          trafd1 = Factory.create :gene_trafd1
          Factory.create :phenotype_attempt, :colony_name => 'Cbx1_A',
                  :mi_attempt => Factory.create(:mi_attempt2_status_gtc, :es_cell => Factory.create(:es_cell, :gene => cbx1), :mi_plan => Factory.create(:mi_plan_with_production_centre, :force_assignment => true,:gene => cbx1))
          Factory.create :phenotype_attempt, :colony_name => 'Cbx1_B',
                  :mi_attempt => Factory.create(:mi_attempt2_status_gtc, :es_cell => Factory.create(:es_cell, :gene => cbx1), :mi_plan => Factory.create(:mi_plan_with_production_centre, :force_assignment => true,:gene => cbx1))
          Factory.create :phenotype_attempt, :colony_name => 'Trafd1_A',
                  :mi_attempt => Factory.create(:mi_attempt2_status_gtc, :es_cell => Factory.create(:es_cell, :gene => trafd1), :mi_plan => Factory.create(:mi_plan_with_production_centre, :force_assignment => true,:gene => trafd1))
          get :index, :format => :json, :marker_symbol_eq => 'Cbx1'
          assert_equal ['Cbx1_A', 'Cbx1_B'], JSON.parse(response.body).map{|i| i['colony_name']}
        end

        should_eventually 'translate sort params when we have any associated fields that can be searched on (thanks, Ransack)'

        should 'allow paginating' do
          ('A'..'F').map { |i| Factory.create :phenotype_attempt, :colony_name => i }
          get :index, 'format' => 'json', :per_page => 3, :page => 2
          assert_equal ['D', 'E', 'F'], JSON.parse(response.body).map{|i| i['colony_name']}
        end

        should 'paginate by 20 by default' do
          30.times { Factory.create :phenotype_attempt }
          get :index, 'format' => 'json'
          assert_equal 20, JSON.parse(response.body).size
        end

      end

      context 'GET /attributes' do
        should 'work' do
          get :attributes
          assert_response :success
          assert_include JSON.parse(response.body).keys, 'readable'
        end
      end

    end # when authenticated

  end
end
