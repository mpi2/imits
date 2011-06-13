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
          sign_in Factory.create(:user)
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

  end
end
