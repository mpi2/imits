require 'test_helper'

class CentresControllerTest < ActionController::TestCase
  context 'Centre controller' do

    should 'require authentication' do
      centre = Centre.find_by_name('WTSI')
      get :show, :id => centre.id, :format => :json
      assert_false response.success?
    end

    context 'GET show' do
      setup do
        @centre = Centre.find_by_name('WTSI')
      end

      should 'get one centre by ID as XML' do
        get :show, :id => @centre.id, :format => :xml
        xml = parse_xml_from_response
        assert_equal @centre.name.to_s, xml.css('centre name').text
      end

      should 'get one centre by ID as JSON' do
        get :show, :id => @centre.id, :format => :json
        json = parse_json_from_response
        assert_equal @centre.name.to_s, json['name']
      end
    end

    context 'GET index' do
      should 'support search helpers as XML' do
        get :index, :name_contains => 'WT', :format => :xml
        xml = parse_xml_from_response
        assert_equal 1, xml.xpath('count(//centre)')
      end

      should 'support search helpers as JSON' do
        get :index, :name_contains => 'WT', :format => :json
        array = parse_json_from_response
        assert_equal 1, array.size
        assert_equal 'WTSI', array.first['name']
      end
    end

  end
end
