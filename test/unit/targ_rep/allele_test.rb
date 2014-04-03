require 'test_helper'

class TargRep::AlleleTest < ActiveSupport::TestCase

  setup do
    @allele = Factory.create(:base_allele)
    # allele has been saved successfully here
  end

  should 'save' do
    @allele = Factory.build(:base_allele)
    assert_true @allele.save
  end

  should have_many(:targeting_vectors)
  should have_many(:es_cells)
  should belong_to(:gene)
  should belong_to(:mutation_type)
  should belong_to(:mutation_subtype)
  should belong_to(:mutation_method)
  should have_one(:genbank_file).dependent(:destroy)

  should accept_nested_attributes_for(:genbank_file).allow_destroy(true)
  should accept_nested_attributes_for(:targeting_vectors).allow_destroy(true)
  should accept_nested_attributes_for(:es_cells).allow_destroy(true)

  [
    :gene, :assembly, :chromosome,
    :strand, :mutation_type, :mutation_method
  ].each do |attribute|
    should validate_presence_of(attribute)
  end

  should_not allow_value(nil).for(:mutation_method)
  should_not allow_value(nil).for(:mutation_type)
  should allow_value(nil).for(:mutation_subtype)

  should ensure_inclusion_of(:strand).in_array(["+", "-"]).with_message("should be '+' or '-'.")
  should ensure_inclusion_of(:strand).in_array(('1'..'19').to_a + ['X', 'Y', 'MT']).with_message("is not a valid mouse chromosome")

  context 'Access association by attribute' do
    should 'return a value for marker_symbol' do
      assert_false @allele.marker_symbol.blank?
      assert_equal @allele.marker_symbol, @allele.gene.marker_symbol
    end
    should 'return a value for mgi_accession_id' do
      assert_false @allele.mgi_accession_id.blank?
      assert_equal @allele.mgi_accession_id, @allele.gene.mgi_accession_id
    end

    should 'return mutation_method_name' do
      name = @allele.mutation_method.name
      assert_equal name, @allele.mutation_method_name
    end

    should 'return mutation_type_name' do
      name = @allele.mutation_type.name
      assert_equal name, @allele.mutation_type_name
    end

    should 'return mutation_subtype_name' do
      name = @allele.mutation_subtype.name
      assert_equal name, @allele.mutation_subtype_name
    end
  end

  should 'default allele types to false' do
    assert_false @allele.class.targeted_allele?
    assert_false @allele.class.gene_trap?
    assert_false @allele.class.hdr_allele?
    assert_false @allele.class.nhej_allele?
    assert_false @allele.class.crispr_targeted_allele?
  end


  context 'targeted_trap' do
    should 'return true if mutation_type is targeted_non_conditional' do
      @allele.mutation_type = TargRep::MutationType.find_by_code('tnc')
      assert_equal 'Yes', @allele.targeted_trap?
    end

    should 'return false if mutation_type is not targeted_non_conditional' do
      @allele.mutation_type = TargRep::MutationType.find_by_code('crd')
      assert_equal 'No', @allele.targeted_trap?
    end
  end

  context '#unique_public_info' do

    should "return an array of unique es cell data for public export" do
      strains = [['JM8A','C57BL/6N-A<tm1Brd>/a'], ['JM8A','C57BL/6N-A<tm1Brd>/a'], ['C2','C57BL/6N'], ['JM8A','C57BL/6N-A<tm1Brd>/a']]
      allele_symbol_superscript = ['tm1e(EUCOMM)Hmgu', 'tm1e(EUCOMM)WTSI', 'tm1e(EUCOMM)WTSI', 'tm1e(EUCOMM)WTSI']
      ikmc_project_ids = ['1', '2', '3', '2']
      allele = Factory.create :base_allele
      (0..3).each do |i|
        Factory.create :es_cell,
                :allele => allele,
                :parental_cell_line => strains[i][0],
                :mgi_allele_symbol_superscript => allele_symbol_superscript[i],
                :ikmc_project_id => ikmc_project_ids[i],
                :pipeline => TargRep::Pipeline.find_by_name!('EUCOMM')
      end

      allele = TargRep::TargetedAllele.find(allele.id)
      unique_es_cells = allele.es_cells.unique_public_info
      assert_equal 3, unique_es_cells.count

      assert unique_es_cells.include?({:strain => strains[0][1], :mgi_allele_symbol_superscript => allele_symbol_superscript[0], :pipeline => 'EUCOMM', :ikmc_project_id => '1', :ikmc_project_status_name => "", :ikmc_project_name => "", :ikmc_project_pipeline => ""})
      assert unique_es_cells.include?({:strain => strains[1][1], :mgi_allele_symbol_superscript => allele_symbol_superscript[1], :pipeline => 'EUCOMM', :ikmc_project_id => '2', :ikmc_project_status_name => "", :ikmc_project_name => "", :ikmc_project_pipeline => ""})
      assert unique_es_cells.include?({:strain => strains[2][1], :mgi_allele_symbol_superscript => allele_symbol_superscript[2], :pipeline => 'EUCOMM', :ikmc_project_id => '3', :ikmc_project_status_name => "", :ikmc_project_name => "", :ikmc_project_pipeline => ""})
    end

    should ', if there are ES cells that differ only in pipeline, just emit a row for the first one' do
      allele = Factory.create :base_allele
      Factory.create :es_cell, :allele => allele,
              :parental_cell_line => 'JM8A',
              :mgi_allele_symbol_superscript => 'tm1a(EUCOMM)WTSI',
              :pipeline => TargRep::Pipeline.find_by_name!('EUCOMM'),
              :ikmc_project_id => '1'
      Factory.create :es_cell, :allele => allele,
              :parental_cell_line => 'JM8A',
              :mgi_allele_symbol_superscript => 'tm1a(EUCOMM)WTSI',
              :pipeline => TargRep::Pipeline.find_by_name!('mirKO'),
              :ikmc_project_id => '1'

      allele = TargRep::TargetedAllele.find(allele.id)
      unique_info = allele.es_cells.unique_public_info
      assert_equal 1, unique_info.size
      expected = {
          :strain => 'C57BL/6N-A<tm1Brd>/a',
          :mgi_allele_symbol_superscript => 'tm1a(EUCOMM)WTSI',
          :ikmc_project_id => '1',
          :ikmc_project_status_name => "",
          :ikmc_project_name => "",
          :ikmc_project_pipeline => "",
          :pipeline => 'EUCOMM'
        }
      assert_equal(expected, unique_info.first)
    end

    should "do not report on report_to_public: false pipelines" do
      strains = [['JM8A','C57BL/6N-A<tm1Brd>/a'], ['JM8A','C57BL/6N-A<tm1Brd>/a'], ['C2','C57BL/6N'], ['JM8A','C57BL/6N-A<tm1Brd>/a']]
      allele_symbol_superscript = ['tm1e(EUCOMM)Hmgu', 'tm1e(EUCOMM)WTSI', 'tm1e(EUCOMM)WTSI', 'tm1e(EUCOMM)WTSI']
      ikmc_project_ids = ['1', '2', '3', '2']
      allele = Factory.create :base_allele
      (0..3).each do |i|
        Factory.create :es_cell,
                :allele => allele,
                :parental_cell_line => strains[i][0],
                :mgi_allele_symbol_superscript => allele_symbol_superscript[i],
                :ikmc_project_id => ikmc_project_ids[i],
                :pipeline => TargRep::Pipeline.find_by_name!('EUCOMM GT')
      end

      allele = TargRep::TargetedAllele.find(allele.id)
      unique_es_cells = allele.es_cells.unique_public_info
      assert_equal 0, unique_es_cells.count
    end
  end

end