# encoding: utf-8

require 'test_helper'

class TargRep::AllelesControllerTest < ActionController::TestCase

  # Note: to make sure url_for works in a functional test,
  # we need to include the two files below
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper

  context 'TargRep::AllelesController' do

    setup do
      sign_in default_user
      Factory.create :allele
    end

    should "allow us to GET /index" do
      # html
      get :index, :format => :html
      assert_response :success
      assert_not_nil assigns(:alleles)

      # json
      get :index, :format => :json
      assert_response :success

      # xml
      get :index, :format => :xml
      assert_response :success
    end

    should "allow us to GET /new" do
      get :new
      assert_response :success
    end

    should "allow us to GET /edit" do
      get :edit, :id => TargRep::TargetedAllele.first.to_param
      assert_response :success
    end

    should "allow us to create allele, targeting vector, es cell and genbank files" do
      mol_struct    = Factory.attributes_for :allele
      targ_vec1     = Factory.build :targeting_vector
      targ_vec2     = Factory.build :targeting_vector
      genbank_file  = Factory.build :genbank_file
      gene          = Factory.create :gene

      mol_struct_count  = TargRep::TargetedAllele.count
      targ_vec_count    = TargRep::TargetingVector.count
      es_cell_count     = TargRep::EsCell.count
      unlinked_es_cells = TargRep::EsCell.no_targeting_vector.count
      linked_es_cells   = TargRep::EsCell.has_targeting_vector.count

      allele = {
        :assembly           => mol_struct[:assembly],
        :gene_id            => gene.id,
        :project_design_id  => mol_struct[:project_design_id],
        :chromosome         => mol_struct[:chromosome],
        :strand             => mol_struct[:strand],
        :mutation_method_id    => mol_struct[:mutation_method].id,
        :mutation_type_id      => mol_struct[:mutation_type].id,
        :mutation_subtype_id   => mol_struct[:mutation_subtype].id,
        :homology_arm_start => mol_struct[:homology_arm_start],
        :homology_arm_end   => mol_struct[:homology_arm_end],
        :cassette_start     => mol_struct[:cassette_start],
        :cassette_end       => mol_struct[:cassette_end],
        :cassette_type      => mol_struct[:cassette_type],
        :cassette           => mol_struct[:cassette],

        :targeting_vectors => [
          # Targeting vector 1 with its ES cells
          {
            :pipeline_id         => targ_vec1[:pipeline_id],
            :ikmc_project_id     => targ_vec1[:ikmc_project_id],
            :name                => targ_vec1[:name],
            :intermediate_vector => targ_vec1[:intermediate_vector],
            :report_to_public    => true,
            :es_cells => [
              Factory.attributes_for(:es_cell, :ikmc_project_id => targ_vec1[:ikmc_project_id], :pipeline_id => targ_vec1[:pipeline_id]),
              Factory.attributes_for(:es_cell, :ikmc_project_id => targ_vec1[:ikmc_project_id], :pipeline_id => targ_vec1[:pipeline_id]),
              Factory.attributes_for(:es_cell, :ikmc_project_id => targ_vec1[:ikmc_project_id], :pipeline_id => targ_vec1[:pipeline_id])
            ]
          },

          # Targeting vector 2 without ES Cells
          {
            :pipeline_id         => targ_vec2[:pipeline_id],
            :ikmc_project_id     => targ_vec2[:ikmc_project_id],
            :name                => targ_vec2[:name],
            :intermediate_vector => targ_vec2[:intermediate_vector],
            :report_to_public => true
          }
        ],

        # ES Cells only related to allele
        :es_cells => [
          Factory.attributes_for(:es_cell, :pipeline_id => targ_vec1[:pipeline_id]),
          Factory.attributes_for(:es_cell, :pipeline_id => targ_vec1[:pipeline_id]),
          Factory.attributes_for(:es_cell, :pipeline_id => targ_vec1[:pipeline_id])
        ],

        :genbank_file => {
          :escell_clone     => genbank_file[:escell_clone],
          :targeting_vector => genbank_file[:targeting_vector]
        }
      }

      post :create, :targ_rep_allele => allele

      assert_equal mol_struct_count + 1, TargRep::TargetedAllele.count, "Controller should have created 1 valid allele."
      assert_equal targ_vec_count + 2, TargRep::TargetingVector.count, "Controller should have created 2 valid targeting vectors."
      assert_equal es_cell_count + 6, TargRep::EsCell.count, "Controller should have created 6 valid ES cells."
      assert_equal unlinked_es_cells + 3, TargRep::EsCell.no_targeting_vector.count, "Controller should have created 3 more ES cells not linked to a targeting vector"
      assert_equal linked_es_cells + 3, TargRep::EsCell.has_targeting_vector.count, "Controller should have created 3 more ES cells linked to a targeting vector"
    end

    should "allow us to create, update and delete a allele we made" do
      allele_attrs = Factory.attributes_for :allele
      allele_attrs[:gene_id] = Factory.create(:gene).id
      allele_attrs[:mutation_method_id]  = allele_attrs.delete(:mutation_method)
      allele_attrs[:mutation_type_id]    = allele_attrs.delete(:mutation_type)
      allele_attrs[:mutation_subtype_id] = allele_attrs.delete(:mutation_subtype)

      # CREATE
      assert_difference('TargRep::TargetedAllele.count') do
        post :create, :allele => allele_attrs
      end
      assert_redirected_to targ_rep_targeted_allele_path(assigns(:allele))

      created_allele = TargRep::TargetedAllele.search(:gene_id_eq => allele_attrs[:gene_id]).result.last
      created_allele.save

      # UPDATE
      allele_attrs = Factory.attributes_for(:allele)
      allele_attrs[:mutation_method_id]  = allele_attrs.delete(:mutation_method)
      allele_attrs[:mutation_type_id]    = allele_attrs.delete(:mutation_type)
      allele_attrs[:mutation_subtype_id] = allele_attrs.delete(:mutation_subtype)

      put :update, { :id => created_allele.id, :allele => allele_attrs }
      assert_redirected_to targ_rep_targeted_allele_path(assigns(:allele))

      ## DELETE
      #back_url = targ_rep_alleles_path
      #@request.env['HTTP_REFERER'] = back_url
      #assert_difference('TargRep::Allele.count', -1) do
      #  delete :destroy, :id => created_allele.id
      #end
      #assert_redirected_to back_url
    end

    should "allow us to create a allele and genbank file" do
      mol_struct    = Factory.attributes_for :allele
      genbank_file  = Factory.attributes_for :genbank_file
      gene          = Factory.create :gene

      mol_struct_count    = TargRep::TargetedAllele.count
      genbank_file_count  = TargRep::GenbankFile.count

      post :create, :allele => {
        :assembly           => mol_struct[:assembly],
        :gene_id            => gene.id,
        :chromosome         => mol_struct[:chromosome],
        :strand             => mol_struct[:strand],
        :mutation_method_id    => mol_struct[:mutation_method].id,
        :mutation_type_id      => mol_struct[:mutation_type].id,
        :mutation_subtype_id   => mol_struct[:mutation_subtype].id,
        :homology_arm_start => mol_struct[:homology_arm_start],
        :homology_arm_end   => mol_struct[:homology_arm_end],
        :cassette_start     => mol_struct[:cassette_start],
        :cassette_end       => mol_struct[:cassette_end],
        :cassette_type      => mol_struct[:cassette_type],
        :cassette           => mol_struct[:cassette],
        :genbank_file => {
          :escell_clone     => genbank_file[:escell_clone],
          :targeting_vector => genbank_file[:targeting_vector]
        }
      }

      assert_true assigns["allele"].valid?, assigns["allele"].errors.full_messages.join(', ')
      assert_redirected_to assigns["allele"], "Not redirected to the new allele"

      assert_equal mol_struct_count + 1, TargRep::TargetedAllele.count, "Controller should have created 1 valid allele."
      assert_equal genbank_file_count + 1, TargRep::GenbankFile.count, "Controller should have created 1 more genbank file"
    end

    should "not create genbank file database entries if the genbank file arguments are empty" do
      mol_struct = Factory.attributes_for :allele
      gene = Factory.create :gene

      mol_struct_count    = TargRep::TargetedAllele.count
      genbank_file_count  = TargRep::GenbankFile.count

      post :create, :allele => {
        :assembly           => mol_struct[:assembly],
        :gene_id            => gene.id,
        :chromosome         => mol_struct[:chromosome],
        :strand             => mol_struct[:strand],
        :mutation_method_id    => mol_struct[:mutation_method].id,
        :mutation_type_id      => mol_struct[:mutation_type].id,
        :mutation_subtype_id   => mol_struct[:mutation_subtype].id,
        :homology_arm_start => mol_struct[:homology_arm_start],
        :homology_arm_end   => mol_struct[:homology_arm_end],
        :cassette_start     => mol_struct[:cassette_start],
        :cassette_end       => mol_struct[:cassette_end],
        :cassette_type      => mol_struct[:cassette_type],
        :cassette           => mol_struct[:cassette],
        :genbank_file       => {
          :escell_clone => '',
          :targeting_vector => ''
        }
      }

      assert_equal mol_struct_count + 1, TargRep::TargetedAllele.count, "Controller should have created 1 valid allele."
      assert_equal genbank_file_count, TargRep::GenbankFile.count, "Controller should not have created any genbank file"
    end

    should "not create genbank file database entries if the genbank file arguments are nil" do
      mol_struct = Factory.attributes_for :allele
      gene = Factory.create :gene
      mol_struct_count    = TargRep::TargetedAllele.count
      genbank_file_count  = TargRep::GenbankFile.count

      post :create, :allele => {
        :assembly           => mol_struct[:assembly],
        :gene_id            => gene.id,
        :chromosome         => mol_struct[:chromosome],
        :strand             => mol_struct[:strand],
        :mutation_method_id    => mol_struct[:mutation_method].id,
        :mutation_type_id      => mol_struct[:mutation_type].id,
        :mutation_subtype_id   => mol_struct[:mutation_subtype].id,
        :homology_arm_start => mol_struct[:homology_arm_start],
        :homology_arm_end   => mol_struct[:homology_arm_end],
        :cassette_start     => mol_struct[:cassette_start],
        :cassette_end       => mol_struct[:cassette_end],
        :cassette_type      => mol_struct[:cassette_type],
        :cassette           => mol_struct[:cassette],
        :genbank_file       => { :escell_clone => nil, :targeting_vector => nil }
      }

      assert_equal mol_struct_count + 1, TargRep::TargetedAllele.count, "Controller should have created 1 valid allele."
      assert_equal genbank_file_count, TargRep::GenbankFile.count, "Controller should not have created any genbank file"
    end

    should "not create an invalid allele" do
      assert_no_difference('TargRep::TargetedAllele.count') do
        post :create, :allele => Factory.attributes_for(:invalid_allele)
      end
      assert_template :new
    end

    should "show an allele" do
      allele_id = TargRep::TargetedAllele.first.id

      # html
      get :show, :format => "html", :id => allele_id
      assert_response :success, "should show allele as html"

      # json
      get :show, :format => "json", :id => allele_id
      assert_response :success, "should show allele as json"

      # xml
      get :show, :format => "xml", :id => allele_id
      assert_response :success, "should show allele as xml"
    end

    should "find and return allele when searching by marker_symbol" do
      mol_struct = Factory.create :allele, :gene => Factory.create(:gene_myolc)

      response = get :index, { :gene_marker_symbol_eq => 'Myo1c' }

      assert_response :success
      assert_select 'tbody tr', 1, "HTML <table> should only have one row/result."
      assert_select 'td', { :text => 'MGI:1923352' }
    end

    should "not allow us to update a allele with invalid parameters" do
      mol_struct_attrs = Factory.attributes_for :allele
      mol_struct_attrs[:gene_id] = Factory.create(:gene).id
      mol_struct_attrs[:mutation_method_id]  = mol_struct_attrs.delete(:mutation_method)
      mol_struct_attrs[:mutation_type_id]    = mol_struct_attrs.delete(:mutation_type)
      mol_struct_attrs[:mutation_subtype_id] = mol_struct_attrs.delete(:mutation_subtype)

      # CREATE a valid Molecular Structure
      assert_difference('TargRep::TargetedAllele.count') do
        post :create, :allele => mol_struct_attrs
      end
      assert_redirected_to targ_rep_targeted_allele_path(assigns(:allele))

      created_mol_struct = TargRep::TargetedAllele.search(:mgi_accession_id_eq => mol_struct_attrs[:mgi_accession_id]).result.first

      # UPDATE - should fail
      put :update, :id => created_mol_struct.id,
        :allele => {
          :chromosome => "WRONG CHROMOSOME",
          :strand     => "WRONG STRAND"
        }
      assert_template :edit
    end

    should "not allow us to delete a allele when we're not the creator" do
      # Permission will be denied here because we are not deleting with the owner
      assert_no_difference('TargRep::TargetedAllele.count') do
        delete :destroy, :id => TargRep::TargetedAllele.first.id
      end
      assert_response 302
    end

    should "return 404 if we try to request a genbank file that doesn't exist" do
      allele_without_gb = Factory.create :allele

      [:escell_clone_genbank_file, :targeting_vector_genbank_file].each do |route|
        get route, :id => allele_without_gb.id
        assert_response 404
      end
    end

    should "return render if we try to request an image with a genbank file that doesn't exist" do
      allele_without_gb = Factory.create :allele

      [:allele_image, :vector_image].each do |route|
        assert_raise(ActiveRecord::RecordNotFound) { get route, :id => allele_without_gb.id }
      end
    end
  end
end
