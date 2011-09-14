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

        assert_equal 3, MiPlan.count

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

        assert_response :success
        assert_equal 4, MiPlan.count

        post(
          :create,
          :mi_plan => {
            :consortium_id => mip_attrs[:consortium][:id],
            :mi_plan_priority_id => mip_attrs[:mi_plan_priority][:id],
            :mi_plan_status_id => mip_attrs[:mi_plan_status][:id]
          },
          :format => :json
        )

        assert_response 400
        assert JSON.parse(response.body).has_key?('gene')
        assert_equal 4, MiPlan.count
      end
    end
  end
end
