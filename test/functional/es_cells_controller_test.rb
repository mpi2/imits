# encoding: utf-8

require 'test_helper'

class EsCellsControllerTest < ActionController::TestCase
  context 'EsCellsController' do

    setup do
      create_common_test_objects
    end

    should 'require authentication' do
      get :show, :id => EsCell.first.id, :format => :json
      assert_false response.success?
    end

    context 'GET show' do
      setup do
        sign_in default_user
        @es_cell = EsCell.find_by_name('EPD0127_4_E01')
      end

      should 'get one es_cell by ID as XML' do
        get :show, :id => @es_cell.id, :format => :xml
        xml = parse_xml_from_response
        assert_equal @es_cell.name, xml.css('es-cell name').text
      end

      should 'get one es_cell by ID as JSON' do
        get :show, :id => @es_cell.id, :format => :json
        json = parse_json_from_response
        assert_equal @es_cell.name, json['name']
      end
    end

    context 'GET index' do
      setup do
        sign_in default_user
      end

      should 'support search helpers as XML' do
        get :index, :name_contains => '0127', :format => :xml
        xml = parse_xml_from_response
        assert_equal 1, xml.xpath('count(//es-cell)')
        assert_equal 'EPD0127_4_E01', xml.css('es-cell name').text
      end

      should 'support search helpers as JSON' do
        get :index, :name_contains => '0127', :format => :json
        array = parse_json_from_response
        assert_equal 1, array.size
        assert_equal 'EPD0127_4_E01', array.first['name']
      end
    end

    context 'GET mart_search' do
      setup do
        sign_in default_user
      end

      should 'work with es_cell_name param' do
        get :mart_search, :es_cell_name => 'HEPD0549_6_D02', :format => :json
        data = parse_json_from_response
        assert_equal 'HEPD0549_6_D02', data[0]['escell_clone']
      end

      should 'return empty array if passing in blank es_cell_name' do
        get :mart_search, :es_cell_name => nil, :format => :json
        data = parse_json_from_response
        assert_equal 0, data.size
      end

      should 'work with marker_symbol param' do
        get :mart_search, :marker_symbol => 'Trafd1', :format => :json
        data = parse_json_from_response
        expected = %w{
          EPD0127_4_B03
          EPD0127_4_F02
          EPD0127_4_A03
          EPD0127_4_E02
          EPD0127_4_D04
          EPD0127_4_F01
          EPD0127_4_B02
          EPD0127_4_E01
          EPD0127_4_F03
          EPD0127_4_C04
          EPD0127_4_F04
          EPD0127_4_H01
          EPD0127_4_E04
          EPD0127_4_B01
          EPD0127_4_A01
          EPD0127_4_A02
        }
        assert_equal expected.sort, data.map {|i| i['escell_clone']}.sort
      end

      should 'return empty array if passing in blank marker_symbol' do
        get :mart_search, :marker_symbol => nil, :format => :json
        data = parse_json_from_response
        assert_equal 0, data.size
      end
    end

  end
end
