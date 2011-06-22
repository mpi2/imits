# encoding: utf-8

require 'test_helper'

class MiAttemptsControllerTest < ActionController::TestCase
  context 'MiAttempt controller' do

    should 'require authentication with machine interface' do
        mi_attempt = Factory.create(:mi_attempt)
        get :show, :id => mi_attempt.id, :format => :json
        assert ! response.success?
    end

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
          sign_in default_user
        end

        should 'support search helpers as XML' do
          get :index, :colony_name_contains => 'MBS', :format => :xml
          doc = parse_xml_from_response
          assert_equal 2, doc.xpath('count(//mi-attempt)')
          assert_equal 'EPD0127_4_E01', doc.css('mi-attempt:nth-child(1) clone-name').text
          assert_equal 'EPD0127_4_E01', doc.css('mi-attempt:nth-child(2) clone-name').text
        end

        should 'support search helpers as JSON' do
          get :index, :colony_name_contains => 'MBS', :format => :json
          data = parse_json_from_response
          assert_equal 2, data.size
          assert_equal 'EPD0127_4_E01', data[0]['clone_name']
          assert_equal 'EPD0127_4_E01', data[1]['clone_name']
        end
      end
    end

    context 'GET show' do
      setup do
        sign_in default_user
        @mi_attempt = Factory.create(:mi_attempt)
      end

      should 'get one mi attempt by ID as XML' do
        get :show, :id => @mi_attempt.id, :format => :xml
        assert response.success?

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
        sign_in default_user
      end

      def valid_create_for_format(format)
        clone = Factory.create :clone_EPD0127_4_E01_without_mi_attempts
        assert_equal 0, MiAttempt.count
        post :create,
                :mi_attempt => {'clone_name' => clone.clone_name, :production_centre_id => Centre.find_by_name('WTSI').id},
                :format => format

        mi_attempt = MiAttempt.first

        if format == :html
          assert_redirected_to mi_attempt_path(mi_attempt)
        else
          assert_response :success
        end

        assert_equal clone, mi_attempt.clone
        return mi_attempt
      end

      should 'on success redirect to edit page for HTML' do
        valid_create_for_format(:html)
      end

      should_eventually 'on validation errors redirect to edit page and show errors' do
        # TODO clarify with Vivek exactly why colony name should be unique, and
        # what to do with current active mouse lines that have the same colony names
        clone = Factory.create :clone_EPD0127_4_E01_without_mi_attempts
        mi_attempt = Factory.create :mi_attempt, :colony_name => 'MAAB'
        assert_equal 1, MiAttempt.count
        post :create, :mi_attempt => {'clone_name' => 'EPD0127_4_E01', 'colony_name' => 'MAAB'}
        assert_equal 1, MiAttempt.count

        assert ! assigns[:mi_attempt].errors[:colony_name].blank?
        assert ! flash[:alert].blank?
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
        assert_include data['clone_name'], 'cannot be blank'
      end

      should 'return errors with invalid params for XML' do
        post :create, :mi_attempt => {'production_centre_id' => 1}, :format => :xml
        assert_false response.success?

        doc = parse_xml_from_response
        assert_not_equal 0, doc.xpath('count(//error)')
      end

      should 'set production centre from params if specified' do
        user = Factory.create :user, :production_centre => Centre.find_by_name('ICS')
        sign_in user
        clone = Factory.create :clone_EPD0127_4_E01_without_mi_attempts
        post :create,
                :mi_attempt => {'clone_name' => clone.clone_name, 'production_centre_id' => Centre.find_by_name('WTSI')},
                :format => :json
        assert_response :success, response.body

        mi_attempt = MiAttempt.first
        assert_equal 'WTSI', mi_attempt.production_centre.name
      end

      should 'set production centre to logged in user centre if not specified' do
        user = Factory.create :user, :production_centre => Centre.find_by_name('ICS')
        sign_in user
        clone = Factory.create :clone_EPD0127_4_E01_without_mi_attempts
        post :create,
                :mi_attempt => {'clone_name' => clone.clone_name},
                :format => :json
        assert_response :success, response.body

        mi_attempt = MiAttempt.first
        assert_equal 'ICS', mi_attempt.production_centre.name
      end
    end

    context 'PUT update' do
      setup do
        sign_in default_user
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
