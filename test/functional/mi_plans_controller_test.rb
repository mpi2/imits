require 'test_helper'

class MiPlansControllerTest < ActionController::TestCase
  context 'MiPlansController' do

    should 'require authentication' do
      get :gene_selection
      assert_false response.success?
      assert_redirected_to new_user_session_path
    end

    context 'when authenticated' do
      setup do
        sign_in default_user
      end

      should 'create MiPlans with POST /mi_plans.json' do
        Factory.create(:gene_cbx1)
        assert_equal 0, MiPlan.count

        attributes = {
          :marker_symbol => 'Cbx1',
          :consortium_name => 'BaSH',
          :priority => 'High'
        }
        post(:create, :mi_plan => attributes, :format => :json)
        assert_response :success, response.body

        plan = MiPlan.first
        assert_equal plan.as_json, JSON.parse(response.body)
      end

      should 'return errors when creating MiPlans with POST /mi_plans.json' do
        assert_no_difference('MiPlan.count') do
          post(
            :create,
            :mi_plan => {
              :consortium_name => 'BaSH',
              :priority => 'High'
            },
            :format => :json
          )
        end
        assert_response 422
        assert_equal ['cannot be blank'], JSON.parse(response.body)['marker_symbol']
      end

      context 'when deleting via JSON' do
        should 'work' do
          mip = Factory.create :mi_plan, :mi_plan_status_id => MiPlanStatus.find_by_name!('Interest').id
          assert_difference('MiPlan.count', -1) do
            delete( :destroy, :id => mip.id, :format => :json )
          end

          mip2 = Factory.create :mi_plan_with_production_centre,
                  :mi_plan_status_id => MiPlanStatus.find_by_name!('Interest').id
          assert_difference('MiPlan.count', -1) do
            delete(
              :destroy,
              :marker_symbol => mip2.gene.marker_symbol,
              :consortium => mip2.consortium.name,
              :production_centre => mip2.production_centre.name,
              :format => :json
            )
          end
        end

        should 'return error if gene not found' do
          mip3 = Factory.create :mi_plan_with_production_centre,
                  :mi_plan_status_id => MiPlanStatus.find_by_name!('Interest')
          assert_no_difference('MiPlan.count') do
            delete(
              :destroy,
              :marker_symbol => 'Wibble',
              :consortium => mip3.consortium.name,
              :production_centre => mip3.production_centre.name,
              :format => :json
            )
          end
          assert_response 422
          assert JSON.parse(response.body).has_key?('mi_plan')
        end

        should 'return error if trying to delete assigned mi_plans' do
          mip4 = Factory.create :mi_plan_with_production_centre,
                  :mi_plan_status_id => MiPlanStatus.find_by_name!('Assigned').id
          assert_no_difference('MiPlan.count') do
            delete(
              :destroy,
              :marker_symbol => mip4.gene.marker_symbol,
              :consortium => mip4.consortium.name,
              :production_centre => mip4.production_centre.name,
              :format => :json
            )
          end
          assert_response 403
          assert JSON.parse(response.body).has_key?('mi_plan')
        end

        should 'delete the right MiPlan' do
          gene = Factory.create :gene_cbx1
          mip5 = Factory.create :mi_plan,
                  :mi_plan_status    => MiPlanStatus[:Interest],
                  :gene              => gene,
                  :consortium        => Consortium.find_by_name!('MARC'),
                  :production_centre => nil
          mip6 = Factory.create :mi_plan,
                  :mi_plan_status    => MiPlanStatus[:Assigned],
                  :gene              => gene,
                  :consortium        => Consortium.find_by_name!('MARC'),
                  :production_centre => Centre.find_by_name!('DTCC')

          assert_difference('MiPlan.count',-1) do
            delete(
              :destroy,
              :marker_symbol => 'Cbx1',
              :consortium => 'MARC',
              :production_centre => '',
              :format => :json
            )
          end
          assert_nil MiPlan.find_by_id(mip5.id)
          assert_equal mip6, MiPlan.find_by_id(mip6.id)
        end
      end
    end

  end
end
