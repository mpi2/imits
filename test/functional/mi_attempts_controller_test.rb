# encoding: utf-8

require 'test_helper'

class MiAttemptsControllerTest < ActionController::TestCase

  def valid_create_for_format(format)
    es_cell = Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts, :allele => Factory.create(:allele_with_gene_trafd1)
    assert_equal 0, MiAttempt.count
    mi_plan = Factory.create(:mi_plan, :gene => es_cell.gene,
                :production_centre => Centre.find_by_name!('WTSI'),
                :consortium => Consortium.find_by_name!('MGP'),
                :status => MiPlan::Status[:Assigned])

    post( :create,
      :mi_attempt => {
        'es_cell_name' => es_cell.name,
        'mi_plan_id' => mi_plan.id ,
        'mi_date' => Date.today.to_s
      },
      :format => format
    )

    mi_attempt = MiAttempt.first

    if format == :html
      assert_redirected_to mi_attempt_path(mi_attempt)
    else
      assert_response :success
    end

    assert_equal es_cell, mi_attempt.es_cell
    return mi_attempt
  end


  def bad_update_for_format(format)
    Factory.create :mi_attempt2, :colony_name => 'EXISTING COLONY NAME',
            :mi_plan => bash_wtsi_cbx1_plan
    mi_attempt = Factory.create :mi_attempt2,
            :mi_plan => bash_wtsi_cbx1_plan

    put :update, :id => mi_attempt.id,
            :mi_attempt => {'colony_name' => 'EXISTING COLONY NAME'},
            :format => format
    assert_equal response.success?, false
  end

  context 'MiAttempt controller' do

    should 'require authentication with machine interface' do
      mi_attempt = Factory.create(:mi_attempt2)
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

       # should 'work in XML format' do
       #   get :index, :colony_name_cont => 'MBS', :format => :xml
       #   doc = parse_xml_from_response
       #   assert_equal 1, doc.xpath('count(//mi_attempt)'), doc
       #   assert_equal 'EPD0127_4_E01', doc.css('mi_attempt es_cell_name').text
       # end

        should 'work in JSON format' do
          get :index, :colony_name_cont => 'MB', :format => :json
          data = JSON.parse(response.body)
          assert_equal 2, data.size
          assert_equal 'MBSS', data.find {|i| i['es_cell_name'] == 'EPD0127_4_E01'}['colony_name']
          assert_equal 'MBFD', data.find {|i| i['es_cell_name'] == 'EPD0029_1_G04'}['colony_name']
        end

        should 'translate search params' do
          get :index, 'es_cell_marker_symbol_eq' => 'Trafd1', :format => :json
          data = JSON.parse(response.body)
          assert_equal 3, data.size
          assert_equal 3, data.select {|i| i['es_cell_name'] == 'EPD0127_4_E01'}.size
        end

        should 'work if embedded in q parameter' do
          get :index, :q => {'es_cell_name_ci_in' => ['epd0127_4_e01', 'epd0029_1_g04']}, :format => :json
          data = JSON.parse(response.body)
          assert_equal 4, data.size
          assert_equal 'MBFD', data.find {|i| i['es_cell_name'] == 'EPD0029_1_G04'}['colony_name']
          assert_equal 3, data.select {|i| i['es_cell_name'] == 'EPD0127_4_E01'}.size
        end

        should 'filter by status' do
          mi = Factory.create :mi_attempt2
          mi.update_attributes!(:is_active => false)
          get :index, :q => {'status_name_eq' => MiAttempt::Status.micro_injection_aborted.name}, :format => :json
          data = JSON.parse(response.body)
          assert_equal 1, data.size
          assert_equal mi.id, data.first['id']
        end
      end

      should 'paginate by default for JSON' do
        200.times {Factory.create :mi_attempt2}
        get :index, :format => :json
        data = JSON.parse(response.body)
        assert_equal 20, data.size
      end

      #should 'paginate by default for XML' do
      #  200.times {Factory.create :mi_attempt2}
      #  get :index, :format => :xml
      #  assert_equal 20, response.body.scan('<mi_attempt>').size
      #end

      should 'allow pagination' do
        200.times {Factory.create :mi_attempt2}
        get :index, :format => :json, :per_page => 50
        data = JSON.parse(response.body)
        assert_equal 50, data.size

        get :index, :format => :json, :per_page => 0
        data = JSON.parse(response.body)
        assert_equal 20, data.size
      end

      should 'sort by ID by default' do
        Factory.create :mi_attempt2, :id => 500
        Factory.create :mi_attempt2, :id => 20
        Factory.create :mi_attempt2, :id => 200

        get :index, 'format' => 'json'
        all_ids = JSON.parse(response.body).map {|i| i['id']}
        assert_equal all_ids.sort, all_ids
      end

      should 'sort by other parameters' do
        Factory.create :mi_attempt2, :id => 500, :colony_name => 'EPD_001'
        Factory.create :mi_attempt2, :id => 20, :colony_name => 'EPD_003'
        Factory.create :mi_attempt2, :id => 200, :colony_name => 'EPD_002'
        get :index, 'format' => 'json', 'sorts' => 'colony_name'

        names = JSON.parse(response.body).map {|i| i['colony_name']}
        assert_equal names.sort, names
      end

      context 'JSON extended_response' do
        should 'be included when parameter is passed' do
          mi = Factory.create(:mi_attempt2).to_public
          get :index, :format => 'json', 'extended_response' => 'true'
          expected = {
            'mi_attempts' => [mi.as_json],
            'success' => true,
            'total' => 1
          }
          got = JSON.parse(response.body)
          assert_equal expected['success'], got['success']
          assert_equal expected['total'], got['total']
          assert_equal expected['mi_attempts'].size, got['mi_attempts'].size
          assert_equal expected['mi_attempts'][0].keys.sort, got['mi_attempts'][0].keys.sort
          expected['mi_attempts'][0].each do |key, value|
            assert_equal value.try(:to_s), got['mi_attempts'][0][key].try(:to_s), "Attribute #{key} differed"
          end
        end

        should 'include total MI attempts' do
          100.times { Factory.create :mi_attempt2 }
          get :index, :format => 'json', 'extended_response' => 'true', :per_page => 25
          got = JSON.parse(response.body)
          assert_equal true, got['success']
          assert_equal 25, got['mi_attempts'].size
          assert_equal 100, got['total']
        end

        should 'include total MI attempts from filtering' do
          found_mis = [
            Factory.create(:mi_attempt2, :colony_name => 'ABC_1'),
            Factory.create(:mi_attempt2, :colony_name => 'ABC_2'),
            Factory.create(:mi_attempt2, :colony_name => 'ABC_3'),
            Factory.create(:mi_attempt2, :colony_name => 'ABC_4'),
            Factory.create(:mi_attempt2, :colony_name => 'ABC_5'),
            Factory.create(:mi_attempt2, :colony_name => 'ABC_6'),
            Factory.create(:mi_attempt2, :colony_name => 'ABC_7'),
            Factory.create(:mi_attempt2, :colony_name => 'ABC_8'),
            Factory.create(:mi_attempt2, :colony_name => 'ABC_9')
          ]
          Factory.create(:mi_attempt2, :colony_name => 'DEF_1')
          get :index, :format => 'json', 'extended_response' => 'true', :per_page => 5, 'colony_name_cont' => 'ABC', 'sorts' => 'colony_name ASC'
          got = JSON.parse(response.body)
          assert_equal true, got['success']
          assert_equal 5, got['mi_attempts'].size
          assert_equal 9, got['total']
          assert_equal found_mis[0..4].map(&:id).sort, got['mi_attempts'].map{|i| i['id']}
        end
      end
    end

    context 'GET show' do
      setup do
        sign_in default_user
        @mi_attempt = Factory.create(:mi_attempt2).to_public
      end

      #should 'get one mi attempt by ID as XML' do
      #  get :show, :id => @mi_attempt.id, :format => :xml
      #  assert response.success?
      #
      #  doc = parse_xml_from_response
      #  assert_equal @mi_attempt.id, doc.css('mi_attempt id').text.to_i
      #end

      should 'get one mi attempt by ID as JSON' do
        get :show, :id => @mi_attempt.id, :format => :json
        data = JSON.parse(response.body)
        assert_equal @mi_attempt.id, data['id']
      end
    end

    context 'GET history' do
      setup do
        sign_in default_user
        @mi_attempt = Factory.create(:mi_attempt2).to_public
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

      should 'on success redirect to edit page for HTML' do
        valid_create_for_format(:html)
        assert flash[:alert].blank?
      end

      should 'on validation errors redirect to edit page and show errors' do

        es_cell = Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts, :allele => Factory.create(:allele_with_gene_trafd1)
        mi_attempt = Factory.create :mi_attempt2, :colony_name => 'MAAB'
        mi_plan = (Factory.create :mi_plan, :gene => es_cell.gene,
                    :production_centre => Centre.find_by_name!('ICS'),
                    :consortium => Consortium.find_by_name!('BaSH'),
                    :status => MiPlan::Status[:Assigned])

        assert_equal 1, MiAttempt.count
        post :create, :mi_attempt => {
          'es_cell_name' => 'EPD0127_4_E01',
          'colony_name' => 'MAAB',
          'mi_plan_id'  => mi_plan.id,
          'mi_date' => Date.today.to_s
        }
        assert_equal 1, MiAttempt.count

        assert ! assigns[:mi_attempt].errors[:external_ref].blank?
        assert ! flash[:alert].blank?
      end

      should 'work with valid params for JSON' do
        mi = valid_create_for_format(:json)
        data = JSON.parse(response.body)
        assert_equal mi.id, data['id']
      end

      should 'authorize the MI belongs to the user\'s production centre for REST only' do
        assert_equal 'WTSI', default_user.production_centre.name
        es_cell = Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts, :allele => Factory.create(:allele_with_gene_trafd1)
        mi_plan = (Factory.create :mi_plan, :gene => es_cell.gene,
                     :production_centre => Centre.find_by_name!('ICS'),
                     :consortium => Consortium.find_by_name!('BaSH'),
                     :status => MiPlan::Status[:Assigned])
        post :create, :mi_attempt => {
          'es_cell_name' => es_cell.name,
          'mi_plan_id' => mi_plan.id,
          'mi_date' => '2011-05-01',
        }, :format => :json
        assert_response 401, response.body
        expected = {
          'error' => 'Cannot create/update data for other production centres'
        }
        assert_equal(expected, JSON.parse(response.body))
      end

    end

    context 'PUT update' do
      setup do
        sign_in default_user
      end

      #should "work with valid params for XML" do
      #  mi_attempt = Factory.create :mi_attempt2, :mi_plan => bash_wtsi_cbx1_plan, :total_blasts_injected => nil
      #
      #  put :update, :id => mi_attempt.id,
      #          :mi_attempt => {'total_blasts_injected' => 1},
      #          :format => :xml
      #  assert_response :success
      #
      #  mi_attempt.reload
      #  assert_equal 1, mi_attempt.total_blasts_injected
      #end

      should "work with valid params for JSON" do
        mi_attempt = Factory.create :mi_attempt2, :mi_plan => bash_wtsi_cbx1_plan, :total_blasts_injected => nil

        put :update, :id => mi_attempt.id,
                :mi_attempt => {'total_blasts_injected' => 1},
                :format => :json
        assert_response :success

        mi_attempt.reload
        assert_equal 1, mi_attempt.total_blasts_injected

        assert_equal JSON.parse(mi_attempt.to_public.to_json), JSON.parse(response.body)
      end

      should 'return errors with invalid params for JSON' do
        bad_update_for_format(:json)
        data = JSON.parse(response.body)
        assert_include data['errors']['external_ref'], 'has already been taken'
      end

      #should 'return errors with invalid params for XML' do
      #  bad_update_for_format(:xml)
      #  doc = parse_xml_from_response
      #  assert_not_equal 0, doc.xpath('count(//error)')
      #end

      should 'take extended_response parameter into account for JSON' do
        mi_attempt = Factory.create(:mi_attempt2, :mi_plan => bash_wtsi_cbx1_plan, :total_blasts_injected => nil).to_public

        put :update, :id => mi_attempt.id,
                :mi_attempt => {'total_blasts_injected' => 1},
                :format => 'json', 'extended_response' => true
        assert_response :success

        got = JSON.parse(response.body)
        mi_attempt.reload
        expected = {
          'total' => 1,
          'mi_attempts' => JSON.parse(mi_attempt.to_json),
          'success' => true
        }
        assert_equal expected['mi_attempts'], got['mi_attempts']
        assert_equal expected, got
      end

      should 'authorize the MI belongs to the user\'s production centre' do
        assert_equal 'WTSI', default_user.production_centre.name
        mi_attempt = Factory.create :mi_attempt2, :total_blasts_injected => nil,
                :mi_plan => TestDummy.mi_plan('MGP', 'ICS')

        put :update, :id => mi_attempt.id,
                :mi_attempt => {'total_blasts_injected' => 1},
                :format => :json
        assert_response 401, response.status
        expected = {
          'error' => 'Cannot create/update data for other production centres'
        }
        assert_equal(expected, JSON.parse(response.body))
      end
    end

    context 'GET /attributes' do
      should 'work' do
        sign_in default_user
        get :attributes
        assert_response :success
        assert_include JSON.parse(response.body).keys, 'readable'
      end
    end

  end
end
