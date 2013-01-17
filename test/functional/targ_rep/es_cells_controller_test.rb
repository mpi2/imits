# encoding: utf-8

require 'test_helper'

class TargRep::EsCellsControllerTest < ActionController::TestCase

  context 'TargRep::EsCellsController' do

    setup do

      sign_in default_user

      es_cell_hepd0549_6_d02 = Factory.create(:es_cell, :name => 'HEPD0549_6_D02', :allele => Factory.create(:allele))

      gene_trafd1 = Factory.create(:gene_trafd1)
      allele_trafd1 = Factory.create(:allele, :gene => gene_trafd1)

      @trafd1_es_cells = %w{
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

      @trafd1_es_cells.each do |es_cell_name|
        Factory.create(:es_cell, :name => es_cell_name, :allele => allele_trafd1)
      end
      
    end

  should "allow us to GET /index" do
    get :index, :format => :json
    assert_response :success
  end

  should "not allow us to GET /new" do
    assert_raise(ActionController::UnknownAction) { get :new }
  end

  should "not allow us to GET /edit without a cell id" do
    assert_raise(ActionController::UnknownAction) { get :edit }
  end

  should "allow us to create, update and delete an es_cell we made" do
    es_cell_attrs = Factory.attributes_for :es_cell

    # CREATE
    assert_difference('TargRep::EsCell.count') do
      post :create, :format => :json, :targ_rep_es_cell => {
        :name                => es_cell_attrs[:name],
        :parental_cell_line  => es_cell_attrs[:parental_cell_line],
        :targeting_vector_id => TargRep::EsCell.first.targeting_vector_id,
        :allele_id           => TargRep::EsCell.first.allele_id,
        :mgi_allele_id       => es_cell_attrs[:mgi_allele_id],
        :pipeline_id         => TargRep::Pipeline.first.id
      }
    end
    assert_response :success, "Could not create ES Cell"

    created_es_cell = TargRep::EsCell.find_by_name es_cell_attrs[:name]
    created_es_cell.save!

    # UPDATE
    put :update, :format => :json, :id => created_es_cell.id, :es_cell => { :name => 'new name' }
    assert_response :success, "Could not update ES Cell"

    # DELETE
    #assert_difference('TargRep::EsCell.count', -1) do
    #  delete :destroy, :format => :json, :id => created_es_cell.id
    #end
    #assert_response :success, "Could not delete ES Cell"
  end

  should "allow us to create without providing a targeting vector" do
    es_cell_attrs = Factory.attributes_for :es_cell

    assert_difference('TargRep::EsCell.count') do
      response = post :create, :format => :json, :targ_rep_es_cell => {
        :name               => es_cell_attrs[:name],
        :parental_cell_line => es_cell_attrs[:parental_cell_line],
        :allele_id          => TargRep::EsCell.first.allele_id,
        :mgi_allele_id      => es_cell_attrs[:mgi_allele_id],
        :pipeline_id        => TargRep::Pipeline.first.id
      }
    end
    assert_response :success
  end

  should "show an es_cell" do
    es_cell_id = TargRep::EsCell.first.id

    get :show, :format => "html", :id => es_cell_id
    assert_response 406, "Controller should not allow HTML display"

    get :show, :format => "json", :id => es_cell_id
    assert_response :success, "Controller does not allow JSON display"

    get :show, :format => "xml", :id => es_cell_id
    assert_response :success, "Controller does not allow XML display"
  end

  should "not allow us to rename an existing cell to the same name as another cell" do
    es_cell_attrs   = Factory.attributes_for :es_cell
    another_escell  = Factory.create :es_cell

    # CREATE a valid ES Cell
    assert_difference('TargRep::EsCell.count') do
      post :create, :format => :json, :targ_rep_es_cell => {
        :name                => es_cell_attrs[:name],
        :parental_cell_line  => es_cell_attrs[:parental_cell_line],
        :targeting_vector_id => TargRep::EsCell.first.targeting_vector_id,
        :allele_id           => TargRep::EsCell.first.allele_id,
        :mgi_allele_id       => es_cell_attrs[:mgi_allele_id],
        :pipeline_id         => TargRep::Pipeline.first.id
      }
    end
    assert_response :success

    created_es_cell = TargRep::EsCell.find_by_name es_cell_attrs[:name]

    # UPDATE - should fail as we're trying to enter a duplicate name
    put :update, :format => :json, :id => created_es_cell.id, :targ_rep_es_cell => { :name => another_escell.name }
    assert_response 400
  end

  should "not allow us to delete an es_cell when we're not the creator" do
    # Permission will be denied here because we are not deleting as the creator
    assert_no_difference('TargRep::EsCell.count') do
      delete :destroy, :format => :json, :id => TargRep::EsCell.first.id
    end
    assert_response 302
  end

  should "allow us to reparent an es_cell if we need to" do
    es_cell        = Factory.create :es_cell, { :targeting_vector => nil }
    current_parent = es_cell.allele
    new_parent     = Factory.create :allele

    assert_equal es_cell.allele_id, current_parent.id, "WTF? The es_cell doesn't have the correct allele_id in the first place..."

    put :update, :format => :json, :id => es_cell.id, :targ_rep_es_cell => { :allele_id => new_parent.id }
    assert_response :success

    es_cell = TargRep::EsCell.find(es_cell.id)

    assert_not_equal es_cell.allele_id, current_parent.id, "Ooops, we haven't switched parents..."
    assert_equal es_cell.allele_id, new_parent.id, "Ooops, we haven't switched parents..."
  end

  should "allow us to interact with the /bulk_edit view" do
    get :bulk_edit
    assert_response :success, "Unable to open /es_cells/bulk_edit"

    post :bulk_edit, :es_cell_names => TargRep::EsCell.first.name
    assert_response :success, "Unable to open /es_cells/bulk_edit with an es_cell_names parameter"
  end

  should "show an es_cell (with new distribution_qc)" do

    es_cell = Factory.create :es_cell

    wtsi_distribution_qc = Factory.create(:distribution_qc, { :es_cell => es_cell, :es_cell_distribution_centre => TargRep::EsCellDistributionCentre.find_by_name!('WTSI') } )
    komp_centre = Factory.create(:distribution_qc, { :es_cell => es_cell, :es_cell_distribution_centre => TargRep::EsCellDistributionCentre.find_by_name!('KOMP') } )
    eucomm_centre = Factory.create(:distribution_qc, { :es_cell => es_cell, :es_cell_distribution_centre => TargRep::EsCellDistributionCentre.find_by_name!('EUCOMM') } )

    es_cell_id = es_cell.id

    get :show, :format => :html, :id => es_cell_id
    assert_response 406, "Controller should not allow HTML display"

    response = get :show, :format => :json, :id => es_cell_id
    assert_response :success, "Controller does not allow JSON display"

    object = JSON.load response.body

    found = false

    object['distribution_qcs'].each do |distribution_qc|
      distribution_qc.keys.each do |key|
        next if %W(es_cell_distribution_centre_name es_cell_distribution_centre_id id).include? key
        assert_equal wtsi_distribution_qc[key.underscore.to_sym], distribution_qc[key], "Expected #{wtsi_distribution_qc[key.underscore.to_sym]} got #{distribution_qc[key]} for #{key}"
        found = true
      end
    end

    assert found, "Did not find expected values (1)!"

    get :show, :format => "xml", :id => es_cell_id
    assert_response :success, "Controller does not allow XML display"
  end

  should "update an es_cell (with new distribution_qc)" do
    wtsi_distribution_qc = Factory.create :distribution_qc, { :es_cell_distribution_centre => TargRep::EsCellDistributionCentre.find_by_name!('WTSI') }
    es_cell = wtsi_distribution_qc.es_cell
    id = wtsi_distribution_qc.id

    target = {
      :id => id,
      :five_prime_sr_pcr => ['pass', 'fail'].sample,
      :three_prime_sr_pcr => ['pass', 'fail'].sample,
      :copy_number => ['pass', 'fail'].sample,
      :five_prime_lr_pcr => ['pass', 'fail'].sample,
      :three_prime_lr_pcr => ['pass', 'fail'].sample,
      :thawing => ['pass', 'fail'].sample,
      :loa => ['pass', 'fail', 'passb'].sample,
      :loxp => ['pass', 'fail'].sample,
      :lacz => ['pass', 'fail'].sample,
      :chr1 => ['pass', 'fail'].sample,
      :chr8a => ['pass', 'fail'].sample,
      :chr8b => ['pass', 'fail'].sample,
      :chr11a => ['pass', 'fail'].sample,
      :chr11b => ['pass', 'fail'].sample,
      :chry => ['pass', 'fail', 'passb'].sample,
      :karyotype_low => [0.1, 0.2, 0.3, 0.4, 0.5].sample,
      :karyotype_high => [0.1, 0.2, 0.3, 0.4, 0.5].sample
    }

    put :update, :format => :json, :id => es_cell.id, :targ_rep_es_cell => { :distribution_qcs_attributes => [ target ] }
    assert_response :success

    response = get :show, :format => :json, :id => es_cell.id
    assert_response :success, "Controller does not allow JSON display"

    object = JSON.load response.body

    found = false

    if distribution_qc = object['distribution_qcs'].first
      target.delete(:id)
      
      target.keys.each do |key|
        key2 = key.to_s.gsub(/\:/, '')
        assert_equal target[key], distribution_qc[key2], "Expected '#{target[key]}' - found '#{distribution_qc[key2]}' for key #{key}"
      end
        
      found = true
    end

    assert found, "Did not find expected values (2)!"

    dqc = TargRep::DistributionQc.find id

    target.keys.each do |key|
      assert_equal target[key], dqc[key], "Expected '#{target[key]}' - found '#{dqc[key]}' for key #{key}"
    end
  end

  should "create an es_cell (with new distribution_qc) using only centre name" do
    es_cell_attrs = Factory.attributes_for :es_cell 

    assert_difference('TargRep::EsCell.count') do
      post :create, :format => :json, :targ_rep_es_cell => {
        :name                => es_cell_attrs[:name],
        :parental_cell_line  => es_cell_attrs[:parental_cell_line],
        :targeting_vector_id => TargRep::EsCell.first.targeting_vector_id,
        :allele_id           => TargRep::EsCell.first.allele_id,
        :mgi_allele_id       => es_cell_attrs[:mgi_allele_id],
        :pipeline_id         => TargRep::Pipeline.first.id
      }
    end

    es_cell = TargRep::EsCell.last

    assert_equal es_cell.name, es_cell_attrs[:name]
    assert_equal es_cell.parental_cell_line, es_cell_attrs[:parental_cell_line]
    assert_equal es_cell.targeting_vector_id, TargRep::EsCell.first.targeting_vector_id
    assert_equal es_cell.allele_id, TargRep::EsCell.first.allele_id
    assert_equal es_cell.mgi_allele_id, es_cell_attrs[:mgi_allele_id]
    assert_equal es_cell.pipeline_id, TargRep::Pipeline.first.id
    assert_equal 0, es_cell.distribution_qcs.size

    response = get :show, :format => :json, :id => es_cell.id
    assert_response :success, "Controller does not allow JSON display"

    target = {
      :es_cell_distribution_centre_id => TargRep::EsCellDistributionCentre.find_by_name('WTSI').id,
      :five_prime_sr_pcr => ['pass', 'fail'].sample,
      :three_prime_sr_pcr => ['pass', 'fail'].sample,
      :copy_number => ['pass', 'fail'].sample,
      :five_prime_lr_pcr => ['pass', 'fail'].sample,
      :three_prime_lr_pcr => ['pass', 'fail'].sample,
      :thawing => ['pass', 'fail'].sample,
      :loa => ['pass', 'fail', 'passb'].sample,
      :loxp => ['pass', 'fail'].sample,
      :lacz => ['pass', 'fail'].sample,
      :chr1 => ['pass', 'fail'].sample,
      :chr8a => ['pass', 'fail'].sample,
      :chr8b => ['pass', 'fail'].sample,
      :chr11a => ['pass', 'fail'].sample,
      :chr11b => ['pass', 'fail'].sample,
      :chry => ['pass', 'fail', 'passb'].sample,
      :karyotype_low => [0.1, 0.2, 0.3, 0.4, 0.5].sample,
      :karyotype_high => [0.1, 0.2, 0.3, 0.4, 0.5].sample
    }

    put :update, :format => :json, :id => es_cell.id, :targ_rep_es_cell => { :distribution_qcs_attributes => [target] }
    assert_response :success

    es_cell.reload

    id = es_cell.distribution_qcs.first.id

    dqc = TargRep::DistributionQc.find id

    target[:id] = id

    assert_equal 'WTSI', dqc.es_cell_distribution_centre_name

    target.delete(:centre_name)

    target.keys.each do |key|
      assert_equal target[key], dqc[key], "Expected '#{target[key]}' - found '#{dqc[key]}' for key #{key}"
    end

  end

  should "stop creation of a distribution_qc when es_cell_id and centre_id duplicated" do

    es_cell_attrs = Factory.attributes_for( :es_cell )

    assert_difference('TargRep::EsCell.count') do
      post :create, :format => :json, :targ_rep_es_cell => {
        :name                => es_cell_attrs[:name],
        :parental_cell_line  => es_cell_attrs[:parental_cell_line],
        :targeting_vector_id => TargRep::EsCell.first.targeting_vector_id,
        :allele_id           => TargRep::EsCell.first.allele_id,
        :mgi_allele_id       => es_cell_attrs[:mgi_allele_id],
        :pipeline_id         => TargRep::Pipeline.first.id
      }
    end

    es_cell = TargRep::EsCell.last

    assert_equal es_cell.name, es_cell_attrs[:name]
    assert_equal es_cell.parental_cell_line, es_cell_attrs[:parental_cell_line]
    assert_equal es_cell.targeting_vector_id, TargRep::EsCell.first.targeting_vector_id
    assert_equal es_cell.allele_id, TargRep::EsCell.first.allele_id
    assert_equal es_cell.mgi_allele_id, es_cell_attrs[:mgi_allele_id]
    assert_equal es_cell.pipeline_id, TargRep::Pipeline.first.id
    assert_equal 0, es_cell.distribution_qcs.size

    response = get :show, :format => :json, :id => es_cell.id
    assert_response :success, "Controller does not allow JSON display"

    target = {
      :es_cell_distribution_centre_id => TargRep::EsCellDistributionCentre.find_by_name('WTSI').id,
      :five_prime_sr_pcr => ['pass', 'fail'].sample,
      :three_prime_sr_pcr => ['pass', 'fail'].sample,
      :copy_number => ['pass', 'fail'].sample,
      :five_prime_lr_pcr => ['pass', 'fail'].sample,
      :three_prime_lr_pcr => ['pass', 'fail'].sample,
      :thawing => ['pass', 'fail'].sample,
      :loa => ['pass', 'fail', 'passb'].sample,
      :loxp => ['pass', 'fail'].sample,
      :lacz => ['pass', 'fail'].sample,
      :chr1 => ['pass', 'fail'].sample,
      :chr8a => ['pass', 'fail'].sample,
      :chr8b => ['pass', 'fail'].sample,
      :chr11a => ['pass', 'fail'].sample,
      :chr11b => ['pass', 'fail'].sample,
      :chry => ['pass', 'fail', 'passb'].sample,
      :karyotype_low => [0.1, 0.2, 0.3, 0.4, 0.5].sample,
      :karyotype_high => [0.1, 0.2, 0.3, 0.4, 0.5].sample
    }

    put :update, :format => :json, :id => es_cell.id, :targ_rep_es_cell => { :distribution_qcs_attributes => [target] }
    assert_response :success

    es_cell.reload

    id = es_cell.distribution_qcs.first.id

    dqc = TargRep::DistributionQc.find id

    target[:id] = id

    assert_equal 'WTSI', dqc.es_cell_distribution_centre_name

    target.delete(:es_cell_distribution_centre_name)

    target.keys.each do |key|
      assert_equal target[key], dqc[key], "Expected '#{target[key]}' - found '#{dqc[key]}' for key #{key}"
    end

    get :show, :format => :json, :id => es_cell.id
    assert_response :success, "Controller does not allow JSON display"

    target = {
      :es_cell_distribution_centre_id => TargRep::EsCellDistributionCentre.find_by_name('WTSI').id,
      :five_prime_sr_pcr => ['pass', 'fail'].sample,
      :three_prime_sr_pcr => ['pass', 'fail'].sample,
      :copy_number => ['pass', 'fail'].sample,
      :five_prime_lr_pcr => ['pass', 'fail'].sample,
      :three_prime_lr_pcr => ['pass', 'fail'].sample,
      :thawing => ['pass', 'fail'].sample,
      :loa => ['pass', 'fail', 'passb'].sample,
      :loxp => ['pass', 'fail'].sample,
      :lacz => ['pass', 'fail'].sample,
      :chr1 => ['pass', 'fail'].sample,
      :chr8a => ['pass', 'fail'].sample,
      :chr8b => ['pass', 'fail'].sample,
      :chr11a => ['pass', 'fail'].sample,
      :chr11b => ['pass', 'fail'].sample,
      :chry => ['pass', 'fail', 'passb'].sample,
      :karyotype_low => [0.1, 0.2, 0.3, 0.4, 0.5].sample,
      :karyotype_high => [0.1, 0.2, 0.3, 0.4, 0.5].sample
    }

    put :update, :format => :json, :id => es_cell.id, :targ_rep_es_cell => { :distribution_qcs_attributes => [target] }
    assert_response 400

  end

    ## From iMits

    should 'require authentication' do
      sign_out default_user
      get :mart_search, :marker_symbol => 'Cbx1', :format => :json
      assert_false response.success?
    end

    context 'GET mart_search' do
      setup do
        sign_in default_user
      end

      should 'work with es_cell_name param' do
        get :mart_search, :es_cell_name => 'HEPD0549_6_D02', :format => :json
        data = JSON.parse(response.body)
        assert_equal 'HEPD0549_6_D02', data[0]['name']
      end

      should 'return empty array if passing in blank es_cell_name' do
        get :mart_search, :es_cell_name => nil, :format => :json
        data = JSON.parse(response.body)
        assert_equal 0, data.size
      end

      should 'work with marker_symbol param' do

        get :mart_search, :marker_symbol => 'Trafd1', :format => :json
        data = JSON.parse(response.body)
        assert_equal @trafd1_es_cells.sort, data.map {|i| i['name']}.sort

      end

      should 'return empty array if passing in blank marker_symbol' do
        get :mart_search, :marker_symbol => nil, :format => :json
        data = JSON.parse(response.body)
        assert_equal 0, data.size
      end
    end

  end
end
