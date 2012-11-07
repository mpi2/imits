require 'test_helper'

class SolrUpdate::Queue::ItemsControllerTest < ActionController::TestCase
  context 'SolrUpdate::Queue::ItemsController' do

    should 'require authentication' do
      get :index
      assert_false response.success?
      assert_redirected_to new_user_session_path
    end

    context 'when authenticated' do
      setup do
        sign_in default_user
      end

      context 'GET /index' do
        should 'get back items' do
          expected_items = 3.times.map { Factory.create :solr_update_queue_item_mi_attempt }
          get :index, :format => :json
          assert_response :success

          got_items = JSON.parse(response.body)

          assert_equal expected_items.map {|i| i['id']}.sort, got_items.map {|i| i['id']}.sort
        end

        should 'paginate' do
          10.times { Factory.create :solr_update_queue_item_mi_attempt }
          get :index, :format => :json, :page => 2, :per_page => 3
          assert_response :success
          assert_equal 3, JSON.parse(response.body).size
        end

        should 'filter with ransack' do
          Factory.create :solr_update_queue_item_phenotype_attempt
          Factory.create :solr_update_queue_item_phenotype_attempt
          Factory.create :solr_update_queue_item_mi_attempt

          get :index, :format => :json, :phenotype_attempt_id_not_null => true
          assert_response :success

          items_data = JSON.parse(response.body)
          assert_equal 2, items_data.size
        end

        should 'respond with ExtJS compatible response' do
          Factory.create :solr_update_queue_item_mi_attempt
          get :index, :format => :json, :extended_response => true
          assert_response :success
          assert_equal ['solr_update_queue_items', 'success', 'total'].sort,
                  JSON.parse(response.body).keys
        end
      end
    end

  end
end
