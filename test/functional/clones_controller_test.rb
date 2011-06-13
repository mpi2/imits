# encoding: utf-8

require 'test_helper'

class ClonesControllerTest < ActionController::TestCase
  context 'ClonesController' do

    setup do
      create_common_test_objects
    end

    context 'GET show' do
      setup do
        @clone = Clone.find_by_clone_name('EPD0127_4_E01')
      end

      should 'get one clone by ID as XML' do
        get :show, :id => @clone.id, :format => :xml
        xml = parse_xml_from_response
        assert_equal @clone.clone_name, xml.css('clone clone_name').text
      end

      should 'get one clone by ID as JSON' do
        get :show, :id => @clone.id, :format => :json
        json = parse_json_from_response
        assert_equal @clone.clone_name, json['clone_name']
      end
    end

    context 'GET index' do
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

  end
end
