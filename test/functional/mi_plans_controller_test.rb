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

      context 'POST create' do
        should 'create MiPlans' do
          Factory.create(:gene_cbx1)
          assert_equal 0, MiPlan.count

          attributes = {
            :marker_symbol => 'Cbx1',
            :consortium_name => 'BaSH',
            :priority_name => 'High'
          }
          post(:create, :mi_plan => attributes, :format => :json)
          assert_response :success, response.body

          plan = Public::MiPlan.first
          assert_equal plan.as_json, JSON.parse(response.body)
        end

        should 'use Public::MiPlan, not MiPlan' do
          gene = Factory.create :gene
          attributes = {
            :gene_id => 1,
            :consortium_id => 1,
            :priority_id => 1
          }
          post(:create, :mi_plan => attributes, :format => :json)
          assert_response 422
        end

        should 'return errors when creating MiPlans' do
          assert_no_difference('MiPlan.count') do
            post(
              :create,
              :mi_plan => {
                :consortium_name => 'BaSH',
                :priority_name => 'High'
              },
              :format => :json
            )
          end
          assert_response 422
          assert_equal ['cannot be blank'], JSON.parse(response.body)['marker_symbol']
        end

        should 'return errors when trying to create duplicate-but-with-production-centre to existing one' do
          cbx1 = Factory.create :gene_cbx1
          bash = Consortium.find_by_name!('BaSH')
          mi_plan = Factory.create :mi_plan, :gene => cbx1, :consortium => bash, :production_centre => nil
          assert_no_difference('MiPlan.count') do
            post :create, :mi_plan => {
              :marker_symbol => 'Cbx1',
              :consortium_name => 'BaSH',
              :production_centre_name => 'WTSI',
              :priority_name => 'High'
            }, :format => :json
          end
          assert_response 422, response.body
          message = 'Cbx1 has already been selected by BaSH without a production centre, please add your production centre to that selection'
          assert_equal({'error' => message}, JSON.parse(response.body))
        end
      end

      context 'DELETE destroy' do
        should 'work' do
          mip = Factory.create :mi_plan, :status_id => MiPlan::Status.find_by_name!('Interest').id
          assert_difference('MiPlan.count', -1) do
            delete( :destroy, :id => mip.id, :format => :json )
          end

          mip2 = Factory.create :mi_plan_with_production_centre,
                  :status_id => MiPlan::Status.find_by_name!('Interest').id
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
                  :status_id => MiPlan::Status.find_by_name!('Interest')
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

        should 'delete the right MiPlan' do
          gene = Factory.create :gene_cbx1
          mip5 = Factory.create :mi_plan,
                  :status    => MiPlan::Status[:Interest],
                  :gene              => gene,
                  :consortium        => Consortium.find_by_name!('MARC'),
                  :production_centre => nil
          mip6 = Factory.create :mi_plan,
                  :status    => MiPlan::Status[:Assigned],
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

      context 'GET show' do
        should 'find valid one' do
          mi_plan = Public::MiPlan.find(Factory.create(:mi_plan_with_production_centre,
                  :status => MiPlan::Status[:Assigned]))
          get :show, :id => mi_plan.id, :format => :json
          assert response.success?
          assert_equal JSON.parse(response.body), mi_plan.as_json
        end

        should 'return error on non-valid one' do
          get :show, :id => 33, :format => :json
          ! assert response.success?
        end
      end

      context 'PUT update' do
        should 'update with valid params' do
          mi_plan = Public::MiPlan.find(Factory.create(:mi_plan,
                  :priority => MiPlan::Priority.find_by_name!('High')))
          put :update, :id => mi_plan.id, :format => :json,
                  :mi_plan => {:production_centre_name => 'WTSI', :priority_name => 'High'}
          assert response.success?
          mi_plan.reload
          assert_equal ['WTSI', 'High'],
                  [mi_plan.production_centre_name, mi_plan.priority.name]
          assert_equal mi_plan.as_json, JSON.parse(response.body)
        end

        should 'return errors with invalid update' do
          mi_plan = Factory.create :mi_plan
          assert_no_difference('MiPlan.count') do
            put :update, :id => mi_plan.id, :mi_plan => {:priority_name => 'Nonexistent'},
                    :format => :json
          end
          assert_equal({'priority_name' => ["'Nonexistent' does not exist"]}, parse_json_from_response)
          assert_match /^4\d\d$/, response.status.to_s
        end

        should 'return errors if id not found' do
          assert_no_difference('MiPlan.count') do
            put :update, :id => '99999', :mi_plan => {:priority_name => 'Nonexistent'},
                    :format => :json
          end
          assert_match /^4\d\d$/, response.status.to_s
        end

        should 'use Public::MiPlan, not MiPlan' do
          mi_plan = Public::MiPlan.find(Factory.create(:mi_plan,
              :priority => MiPlan::Priority.find_by_name!('High')))
          put :update, :id => mi_plan.id, :format => :json,
                  :mi_plan => {:production_centre_id => Centre.find_by_name!('WTSI').id, :priority_id => MiPlan::Priority.find_by_name!('Low').id}
          assert response.success?
          mi_plan.reload
          assert_not_equal 'WTSI', mi_plan.production_centre_name
          assert_not_equal 'Low', mi_plan.priority.name
        end

      end

      context 'GET index' do
        setup do
          @p1 = Factory.create :mi_plan, :number_of_es_cells_starting_qc => 4,
                  :gene => Factory.create(:gene_cbx1)
          @p2 = Factory.create :mi_plan, :number_of_es_cells_starting_qc => 12,
                  :number_of_es_cells_passing_qc => 2,
                  :gene => Factory.create(:gene, :marker_symbol => 'Xbnf1')
          @p3 = Factory.create :mi_plan, :number_of_es_cells_starting_qc => 3,
                  :number_of_es_cells_passing_qc => 1,
                  :gene => Factory.create(:gene, :marker_symbol => 'Ady3')
          @p4 = Factory.create :mi_plan, :number_of_es_cells_starting_qc => 2,
                  :gene => Factory.create(:gene, :marker_symbol => 'Ebs1')
          @p5 = Factory.create :mi_plan, :number_of_es_cells_starting_qc => 7,
                  :gene => Factory.create(:gene, :marker_symbol => 'Has2')
          @p6 = Factory.create :mi_plan, :number_of_es_cells_starting_qc => 1,
                  :gene => Factory.create(:gene, :marker_symbol => 'Ttgf1')
          @p7 = Factory.create :mi_plan, :number_of_es_cells_starting_qc => 5,
                  :number_of_es_cells_passing_qc => 3,
                  :gene => Factory.create(:gene, :marker_symbol => 'Ide1')
        end

        should 'allow filtering with Ransack' do
          get :index, :format => :json, :number_of_es_cells_starting_qc_gt => 4,
                  :number_of_es_cells_passing_qc_not_eq => 0
          ids = JSON.parse(response.body).map{|i| i['id']}.sort
          assert_equal [@p2.id, @p7.id].sort, ids
        end

        should 'translate search params' do
          get :index, :format => :json, :marker_symbol_eq => 'Cbx1'
          ids = JSON.parse(response.body).map{|i| i['id']}.sort
          assert_equal [@p1.id].sort, ids
        end

        should 'allow paginating' do
          get :index, 'format' => 'json', 'per_page' => 3, 'page' => 2
          assert_equal [@p5.id, @p7.id, @p6.id], parse_json_from_response.map {|i| i['id']}
        end

        should 'paginate by 20 by default' do
          30.times { Factory.create :mi_plan }
          get :index, 'format' => 'json'
          assert_equal 20, parse_json_from_response.size
        end

        should 'sort by marker_symbol by default' do
          get :index, :format => 'json'
          data = parse_json_from_response
          sorted_markers = data.map {|i| i['marker_symbol']}
          assert_equal sorted_markers.sort, sorted_markers
        end

        should 'allow sorting by marker_symbol' do
          get :index, :format => 'json', :sorts => 'marker_symbol asc'
          data = parse_json_from_response
          sorted_markers = data.map {|i| i['marker_symbol']}
          assert_equal sorted_markers.sort, sorted_markers
        end

        should 'allow sorting by a simple field' do
          get :index, :format => 'json', :sorts => 'number_of_es_cells_starting_qc'
          data = parse_json_from_response
          assert_equal [@p6.id, @p4.id], data.map {|i| i['id']}[0..1]
        end
      end

    end # when authenticated

  end
end
