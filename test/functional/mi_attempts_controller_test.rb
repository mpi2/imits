# encoding: utf-8

require 'test_helper'

class MiAttemptsControllerTest < ActionController::TestCase
  context 'MiAttempt controller' do

    context 'GET index' do
      should 'route from /' do
        assert_routing '/', { :controller => 'mi_attempts', :action => 'index' }
      end

      should 'be root path' do
        assert_equal '/', root_path
      end

      context 'support search helpers' do
        setup do
          create_common_test_objects
          sign_in Factory.create(:user) # TODO http basic authentication
        end

        should 'support search helpers as XML' do
          get :index, :colony_name_contains => 'MBS', :format => :xml
          doc = parse_xml_from_response
          assert_equal 2, doc.xpath('count(//mi-attempt)')
          assert_equal '1', doc.css('mi-attempt:nth-child(1) clone-id').text
          assert_equal '1', doc.css('mi-attempt:nth-child(2) clone-id').text
        end

        should 'support search helpers as JSON' do
          get :index, :colony_name_contains => 'MBS', :format => :json
          data = parse_json_from_response
          assert_equal 2, data.size
          assert_equal 1, data[0]['clone_id']
          assert_equal 1, data[1]['clone_id']
        end
      end
    end

    context 'GET show' do
      setup do
        @mi_attempt = Factory.create(:mi_attempt)
        sign_in Factory.create(:user)
      end

      should 'get one mi attempt by ID as XML' do
        get :show, :id => @mi_attempt.id, :format => :xml
        doc = parse_xml_from_response
        assert_equal @mi_attempt.id, doc.css('mi-attempt id').text.to_i
      end

      should 'get one mi attempt by ID as JSON' do
        get :show, :id => @mi_attempt.id, :format => :json
        data = parse_json_from_response
        assert_equal @mi_attempt.id, data['id']
      end
    end

    context 'POST create' do
      setup do
        sign_in Factory.create(:user) # TODO http basic authentication
      end

      def valid_create_for_format(format)
        clone = Factory.create :clone
        assert_equal 0, MiAttempt.count
        post :create,
                :mi_attempt => {'clone_id' => clone.id, 'production_centre_id' => 1},
                :format => format
        assert_response :success

        mi_attempt = MiAttempt.first
        assert_equal clone, mi_attempt.clone
        return mi_attempt
      end

      should 'work with valid params for JSON' do
        mi = valid_create_for_format(:json)
        data = parse_json_from_response
        assert_equal mi.id, data['id']
      end

      should 'work with valid params for XML' do
        mi = valid_create_for_format(:xml)
        doc = parse_xml_from_response
        assert_equal mi.id.to_s, doc.css('id').text
      end

      should 'return errors with invalid params for JSON' do
        post :create, :mi_attempt => {'production_centre_id' => 1}, :format => :json
        assert_false response.success?

        data = parse_json_from_response
        assert_include data['clone'], 'cannot be blank'
      end

      should 'return errors with invalid params for XML' do
        post :create, :mi_attempt => {'production_centre_id' => 1}, :format => :xml
        assert_false response.success?

        doc = parse_xml_from_response
        assert_not_equal 0, doc.xpath('count(//error)')
      end
    end

    context 'PUT update' do
      setup do
        sign_in Factory.create(:user) # TODO http basic authentication
      end

      [:xml, :json].each do |format|
        should "work with valid params for #{format.upcase}" do
          mi_attempt = Factory.create :mi_attempt, :total_blasts_injected => nil

          put :update, :id => mi_attempt.id,
                  :mi_attempt => {'production_centre_id' => 1, 'total_blasts_injected' => 1},
                  :format => format
          assert_response :success

          mi_attempt.reload
          assert_equal 1, mi_attempt.total_blasts_injected
        end
      end

      def bad_update_for_format(format)
        mi_attempt = Factory.create :mi_attempt, :total_blasts_injected => nil

        put :update, :id => mi_attempt.id,
                :mi_attempt => {'production_centre_id' => nil},
                :format => format
        assert_false response.success?
      end

      should 'return errors with invalid params for JSON' do
        bad_update_for_format(:json)
        data = parse_json_from_response
        assert_include data['production_centre'], 'cannot be blank'
      end

      should 'return errors with invalid params for XML' do
        bad_update_for_format(:xml)
        doc = parse_xml_from_response
        assert_not_equal 0, doc.xpath('count(//error)')
      end
    end

  end
end
