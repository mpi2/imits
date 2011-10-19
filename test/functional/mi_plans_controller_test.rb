require 'test_helper'

class MiPlansControllerTest < ActionController::TestCase
  context 'The reports controller' do
    should 'require authentication' do
      get :gene_selection
      assert_false response.success?
      assert_redirected_to new_user_session_path
    end

    context 'when authorised' do
      setup do
        create_common_test_objects
        sign_in default_user
      end

      should 'allow users access to the gene_selection interface' do
        get :gene_selection
        assert response.success?
        assert assigns(:centre_combo_options)
        assert assigns(:consortia_combo_options)
        assert assigns(:priority_combo_options)
        assert assigns(:interest_status_id)
      end

      should 'allow machine access to the create function via json' do
        mip_attrs = Factory.attributes_for(:mi_plan)
        gene      = Factory.create(:gene)

        assert_difference('MiPlan.count',1) do
          post(
            :create,
            :mi_plan => {
              :gene_id => gene.id,
              :consortium_id => mip_attrs[:consortium][:id],
              :mi_plan_priority_id => mip_attrs[:mi_plan_priority][:id],
              :mi_plan_status_id => mip_attrs[:mi_plan_status][:id]
            },
            :format => :json
          )
        end
        assert_response :success

        assert_no_difference('MiPlan.count') do
          post(
            :create,
            :mi_plan => {
              :consortium_id => mip_attrs[:consortium][:id],
              :mi_plan_priority_id => mip_attrs[:mi_plan_priority][:id],
              :mi_plan_status_id => mip_attrs[:mi_plan_status][:id]
            },
            :format => :json
          )
        end
        assert_response 422
        assert JSON.parse(response.body).has_key?('gene')
      end

      should 'allow machine access to the destroy function via json' do
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

        mip3 = Factory.create :mi_plan, :mi_plan_status_id => MiPlanStatus.find_by_name!('Interest')
        assert_no_difference('MiPlan.count') do
          delete(
            :destroy,
            :marker_symbol => 'Wibble',
            :consortium => mip3.consortium.name,
            :production_centre => mip2.production_centre.try(:name),
            :format => :json
          )
        end
        assert_response 422
        assert JSON.parse(response.body).has_key?('mi_plan')

        # Make sure we can't delete assigned mi_plans
        mip4 = Factory.create :mi_plan, :mi_plan_status_id => MiPlanStatus.find_by_name!('Assigned').id
        assert_no_difference('MiPlan.count') do
          delete(
            :destroy,
            :marker_symbol => mip4.gene.marker_symbol,
            :consortium => mip4.consortium.name,
            :production_centre => mip2.production_centre.try(:name),
            :format => :json
          )
        end
        assert_response 403
        assert JSON.parse(response.body).has_key?('mi_plan')

        # Test to make sure we can disambiguate mi_plans
        mip5 = Factory.create :mi_plan,
          :mi_plan_status_id    => MiPlanStatus.find_by_name!('Interest').id,
          :gene_id              => Gene.find_by_marker_symbol!('Myo1c').id,
          :consortium_id        => Consortium.find_by_name!('MARC').id,
          :production_centre_id => nil
        mip6 = Factory.create :mi_plan,
          :mi_plan_status_id    => MiPlanStatus.find_by_name!('Assigned').id,
          :gene_id              => Gene.find_by_marker_symbol!('Myo1c').id,
          :consortium_id        => Consortium.find_by_name!('MARC').id,
          :production_centre_id => Centre.find_by_name!('DTCC').id

        assert_difference('MiPlan.count',-1) do
          delete(
            :destroy,
            :marer_symbol => 'Myo1c',
            :consortium => 'MARC',
            :production_centre => '',
            :format => :json
          )
        end
        assert_raise (ActiveRecord::RecordNotFound) { MiPlan.find_by_id!(mip5.id) }
        assert_equal mip6, MiPlan.find_by_id!(mip6.id)
      end
    end
  end
end
