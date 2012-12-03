require 'test_helper'

class GenesControllerTest < ActionController::TestCase
  context 'GenesController' do

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

      should 'respond with JSON' do
        get :index, :marker_symbol_eq => 'Trafd1', :format => :json
        json = JSON.parse(response.body)
        assert_equal 1, json.size
        assert_equal 'Trafd1', json[0]['marker_symbol']
      end

      should 'respond with extended (ExtJS ready) JSON' do
        get :index, :extended_response => true, :format => :json
        json = JSON.parse(response.body)

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
        json = JSON.parse(response.body)
        assert_equal 2, json.size

        get :index, :filter => [{ 'property' => 'marker_symbol_ci_in', 'value' => ['myo1c','trafd1'] }], :format => :json
        json = JSON.parse(response.body)
        assert_equal 2, json.size
      end

      should 'paginate' do
        200.times { Factory.create :gene }

        get :index, :format => :json
        assert_equal 20, JSON.parse(response.body).size

        get :index, :format => :json, :per_page => 50
        assert_equal 50, JSON.parse(response.body).size
      end
    end

    context 'GET relationship_tree' do
      setup do
        sign_in default_user
      end

      should ', when JSON, render the gene`s relationship tree' do
        gene = stub('gene')
        Gene.expects(:find_by_mgi_accession_id!).with('MGI:9999999991').returns(gene)
        mock_return = ['mock_return']
        gene.expects(:to_extjs_relationship_tree_structure).with().returns(mock_return)

        get :relationship_tree, :id => 'MGI:9999999991', :format => :json
        assert_response :success, response.body
        assert_equal mock_return, JSON.parse(response.body)
      end
    end

  end
end
