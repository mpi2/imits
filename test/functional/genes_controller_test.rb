require 'test_helper'

class GenesControllerTest < ActionController::TestCase
  context 'Gene controller' do
    should 'require authentication' do
      10.times { Factory.create :gene }
      get :index, :format => :json
      assert_false response.success?
    end

    context 'GET index' do
      setup do
        create_common_test_objects
        sign_in default_user
      end

      should 'respond with XML' do
        get :index, :marker_symbol_eq => 'Trafd1', :format => :xml
        xml = parse_xml_from_response
        assert_equal 1, xml.xpath('count(//gene)')
        assert_equal 'Trafd1', xml.xpath('/genes/gene/marker-symbol').text
      end

      should 'respond with JSON' do
        get :index, :marker_symbol_eq => 'Trafd1', :format => :json
        json = parse_json_from_response
        assert_equal 1, json.size
        assert_equal 'Trafd1', json[0]['marker_symbol']
      end

      should 'respond with extended (ExtJS ready) JSON' do
        get :index, :extended_response => true, :format => :json
        json = parse_json_from_response

        assert json.keys.include?('genes')
        assert json.keys.include?('success')
        assert json.keys.include?('total')
        assert_equal true, json['success']
        assert_equal 3, json['total']

        json['genes'].each do |gene_json|
          gene = Gene.find_by_marker_symbol!(gene_json['marker_symbol'])
          assert_equal JSON.parse(gene.to_json), gene_json
        end
      end

      should 'translate search parameters' do
        get :index, :q => { 'marker_symbol_ci_in' => ['myo1c','trafd1'] }, :format => :json
        json = parse_json_from_response
        assert_equal 2, json.size

        get :index, :filter => [{ 'property' => 'marker_symbol_ci_in', 'value' => ['myo1c','trafd1'] }], :format => :json
        json = parse_json_from_response
        assert_equal 2, json.size
      end

      should 'paginate' do
        200.times { Factory.create :gene }

        get :index, :format => :json
        assert_equal 20, parse_json_from_response.size

        get :index, :format => :json, :per_page => 50
        assert_equal 50, parse_json_from_response.size
      end
    end
  end
end
