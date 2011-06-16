# encoding: utf-8

require 'test_helper'

class ClonesControllerTest < ActionController::TestCase
  context 'ClonesController' do

    setup do
      create_common_test_objects
    end

    should 'require authentication' do
      get :show, :id => Clone.first.id, :format => :json
      assert_false response.success?
    end

    context 'GET show' do
      setup do
        sign_in default_user
        @clone = Clone.find_by_clone_name('EPD0127_4_E01')
      end

      should 'get one clone by ID as XML' do
        get :show, :id => @clone.id, :format => :xml
        xml = parse_xml_from_response
        assert_equal @clone.clone_name, xml.css('clone clone-name').text
      end

      should 'get one clone by ID as JSON' do
        get :show, :id => @clone.id, :format => :json
        json = parse_json_from_response
        assert_equal @clone.clone_name, json['clone_name']
      end
    end

    context 'GET index' do
      setup do
        sign_in default_user
      end

      should 'support search helpers as XML' do
        get :index, :clone_name_contains => '0127', :format => :xml
        xml = parse_xml_from_response
        assert_equal 1, xml.xpath('count(//clone)')
        assert_equal 'EPD0127_4_E01', xml.css('clone clone-name').text
      end

      should 'support search helpers as JSON' do
        get :index, :clone_name_contains => '0127', :format => :json
        array = parse_json_from_response
        assert_equal 1, array.size
        assert_equal 'EPD0127_4_E01', array.first['clone_name']
      end
    end

    context 'GET mart_search' do
      setup do
        sign_in default_user
      end

      should 'work with clone_name param' do
        get :mart_search, :clone_name => 'HEPD0549_6_D02', :format => :json
        data = parse_json_from_response
        assert_equal 'HEPD0549_6_D02', data[0]['escell_clone']
      end

      should 'return empty array if passing in blank clone_name' do
        get :mart_search, :clone_name => nil, :format => :json
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
