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
      setup do
        sign_in default_user
      end

      context 'search helpers' do
        setup do
          create_common_test_objects
        end

        should 'work in XML format' do
          get :index, :colony_name_cont => 'MBS', :format => :xml
          doc = parse_xml_from_response
          assert_equal 1, doc.xpath('count(//mi-attempt)')
          assert_equal 'EPD0127_4_E01', doc.css('mi-attempt es-cell-name').text
        end

        should 'work in JSON format' do
          get :index, :colony_name_cont => 'MB', :format => :json
          data = parse_json_from_response
          assert_equal 2, data.size
          assert_equal 'MBSS', data.find {|i| i['es_cell_name'] == 'EPD0127_4_E01'}['colony_name']
          assert_equal 'MBFD', data.find {|i| i['es_cell_name'] == 'EPD0029_1_G04'}['colony_name']
        end

        should 'translate search params' do
          get :index, 'es_cell_marker_symbol_eq' => 'Trafd1', :format => :json
          data = parse_json_from_response
          assert_equal 3, data.size
          assert_equal 3, data.select {|i| i['es_cell_name'] == 'EPD0127_4_E01'}.size
        end

        should 'work if embedded in q parameter' do
          get :index, :q => {'es_cell_name_ci_in' => ['epd0127_4_e01', 'epd0029_1_g04']}, :format => :json
          data = parse_json_from_response
          assert_equal 4, data.size
          assert_equal 'MBFD', data.find {|i| i['es_cell_name'] == 'EPD0029_1_G04'}['colony_name']
          assert_equal 3, data.select {|i| i['es_cell_name'] == 'EPD0127_4_E01'}.size
        end
      end

      should 'paginate by default for JSON' do
        200.times {Factory.create :mi_attempt}
        get :index, :format => :json
        data = parse_json_from_response
        assert_equal 20, data.size
      end

      should 'paginate by default for XML' do
        200.times {Factory.create :mi_attempt}
        get :index, :format => :xml
        assert_equal 20, response.body.scan('<mi-attempt>').size
      end

      should 'allow pagination' do
        200.times {Factory.create :mi_attempt}
        get :index, :format => :json, :per_page => 50
        data = parse_json_from_response
        assert_equal 50, data.size

        get :index, :format => :json, :per_page => 0
        data = parse_json_from_response
        assert_equal 20, data.size
      end

      should 'sort by ID by default' do
        Factory.create :mi_attempt, :id => 500
        Factory.create :mi_attempt, :id => 20
        Factory.create :mi_attempt, :id => 200

        get :index, 'format' => 'json'
        all_ids = parse_json_from_response.map {|i| i['id']}
        assert_equal all_ids.sort, all_ids
      end

      should 'sort by other parameters' do
        Factory.create :mi_attempt, :id => 500, :colony_name => 'EPD_001'
        Factory.create :mi_attempt, :id => 20, :colony_name => 'EPD_003'
        Factory.create :mi_attempt, :id => 200, :colony_name => 'EPD_002'
        get :index, 'format' => 'json', 'sorts' => 'colony_name'

        names = parse_json_from_response.map {|i| i['colony_name']}
        assert_equal names.sort, names
      end

      context 'JSON extended_response' do
        should 'be included when parameter is passed' do
          mi = Factory.create :mi_attempt
          get :index, :format => 'json', 'extended_response' => 'true'
          expected = {
            'mi_attempts' => [mi.as_json],
            'success' => true,
            'total' => 1
          }
          got = parse_json_from_response
          assert_equal expected['success'], got['success']
          assert_equal expected['total'], got['total']
          assert_equal expected['mi_attempts'].size, got['mi_attempts'].size
          assert_equal expected['mi_attempts'][0].keys.sort, got['mi_attempts'][0].keys.sort
          expected['mi_attempts'][0].each do |key, value|
            assert_equal value, got['mi_attempts'][0][key], "Attribute #{key} differed"
          end
        end

        should 'include total MI attempts' do
          100.times { Factory.create :mi_attempt }
          get :index, :format => 'json', 'extended_response' => 'true', :per_page => 25
          got = parse_json_from_response
          assert_equal true, got['success']
          assert_equal 25, got['mi_attempts'].size
          assert_equal 100, got['total']
        end

        should 'include total MI attempts from filtering' do
          found_mis = [
            Factory.create(:mi_attempt, :colony_name => 'ABC_1'),
            Factory.create(:mi_attempt, :colony_name => 'ABC_2')
          ]
          Factory.create(:mi_attempt, :colony_name => 'DEF_1')
          get :index, :format => 'json', 'extended_response' => 'true', :per_page => 25, 'colony_name_cont' => 'ABC'
          got = parse_json_from_response
          assert_equal true, got['success']
          assert_equal 2, got['mi_attempts'].size
          assert_equal 2, got['total']
          assert_equal found_mis.map(&:id).sort, got['mi_attempts'].map{|i| i['id']}
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

    context 'GET history' do
      setup do
        sign_in default_user
        @mi_attempt = Factory.create(:mi_attempt)
      end

      should 'show the history page for a given mi_attempt' do
        get :history, :id => @mi_attempt.id
        assert response.success?
      end
    end

    context 'POST create' do
      setup do
        sign_in default_user
      end

      def valid_create_for_format(format)
        es_cell = Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts
        assert_equal 0, MiAttempt.count
        post(:create, :mi_attempt => {
            'es_cell_name' => es_cell.name,
            :production_centre_name => 'WTSI',
            :consortium_name => 'MGP'
          },
          :format => format)

        mi_attempt = MiAttempt.first

        if format == :html
          assert_redirected_to mi_attempt_path(mi_attempt)
        else
          assert_response :success
        end

        assert_equal es_cell, mi_attempt.es_cell
        return mi_attempt
      end

      should 'on success redirect to edit page for HTML' do
        valid_create_for_format(:html)
        assert flash[:alert].blank?
      end

      should 'on validation errors redirect to edit page and show errors' do
        es_cell = Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts
        mi_attempt = Factory.create :mi_attempt, :colony_name => 'MAAB'
        assert_equal 1, MiAttempt.count
        post :create, :mi_attempt => {'es_cell_name' => 'EPD0127_4_E01', 'colony_name' => 'MAAB', 'consortium_name' => 'EUCOMM-EUMODIC'}
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

      should 'return validation errors for JSON' do
        post :create, :mi_attempt => {'production_centre_name' => 'WTSI'}, :format => :json
        assert_false response.success?

        data = parse_json_from_response
        assert_include data['es_cell_name'], 'cannot be blank'
      end

      should 'return validation errors for XML' do
        post :create, :mi_attempt => {'production_centre_name' => 'WTSI'}, :format => :xml
        assert_false response.success?

        doc = parse_xml_from_response
        assert_not_equal 0, doc.xpath('count(//error)')
      end

      should 'set production centre and consortium from params instead of user if specified' do
        user = Factory.create :user, :production_centre => Centre.find_by_name!('ICS')
        sign_in user
        es_cell = Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts
        post :create,
                :mi_attempt => {'es_cell_name' => es_cell.name, 'production_centre_name' => 'WTSI', 'consortium_name' => 'MGP' },
                :format => :json
        assert_response :success, response.body

        mi_attempt = MiAttempt.first
        assert_equal 'WTSI', mi_attempt.production_centre_name
        assert_equal 'MGP', mi_attempt.consortium_name
      end

      should 'set production centre to logged in user centre if not specified' do
        user = Factory.create :user, :production_centre => Centre.find_by_name!('ICS')
        sign_in user
        es_cell = Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts
        post :create,
                :mi_attempt => {'es_cell_name' => es_cell.name, 'consortium_name' => 'EUCOMM-EUMODIC'},
                :format => :json
        assert_response :success, response.body

        mi_attempt = MiAttempt.first
        assert_equal 'ICS', mi_attempt.production_centre_name
        assert_equal 'EUCOMM-EUMODIC', mi_attempt.consortium_name
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
                  :mi_attempt => {'total_blasts_injected' => 1},
                  :format => format
          assert_response :success

          mi_attempt.reload
          assert_equal 1, mi_attempt.total_blasts_injected
        end
      end

      def bad_update_for_format(format)
        Factory.create :mi_attempt, :colony_name => 'EXISTING COLONY NAME'
        mi_attempt = Factory.create :mi_attempt

        put :update, :id => mi_attempt.id,
                :mi_attempt => {'colony_name' => 'EXISTING COLONY NAME'},
                :format => format
        assert_false response.success?
      end

      should 'return errors with invalid params for JSON' do
        bad_update_for_format(:json)
        data = parse_json_from_response
        assert_include data['colony_name'], 'has already been taken'
      end

      should 'return errors with invalid params for XML' do
        bad_update_for_format(:xml)
        doc = parse_xml_from_response
        assert_not_equal 0, doc.xpath('count(//error)')
      end

      should 'take extended_response parameter into account for JSON' do
        mi_attempt = Factory.create :mi_attempt, :total_blasts_injected => nil

        put :update, :id => mi_attempt.id,
                :mi_attempt => {'total_blasts_injected' => 1},
                :format => 'json', 'extended_response' => true
        assert_response :success

        got = parse_json_from_response
        mi_attempt.reload
        expected = {
          'total' => 1,
          'mi_attempts' => [mi_attempt.as_json],
          'success' => true
        }
        assert_equal expected, got
      end
    end

  end
end
