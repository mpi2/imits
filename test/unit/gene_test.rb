# encoding: utf-8

require 'test_helper'

class GeneTest < ActiveSupport::TestCase
  context 'Gene' do

    context '(misc. tests)' do
      setup do
        Factory.create :gene
      end

      should have_many :es_cells
      should have_many :mi_plans

      should have_db_column(:marker_symbol).of_type(:string).with_options(:null => false, :limit => 75)
      should have_db_column(:mgi_accession_id).of_type(:string).with_options(:null => true, :limit => 40)

      should validate_presence_of :marker_symbol
      should validate_uniqueness_of :marker_symbol
    end

    context '::find_or_create_from_mart_data' do
      should 'find an existing one' do
        gene = Factory.create :gene, :marker_symbol => 'Trafd1', :mgi_accession_id => 'MGI:1923551'
        assert_equal gene, Gene.find_or_create_from_mart_data(
          'es_cell_name' => 'EPD0127_4_E01',
          'marker_symbol' => 'Trafd1',
          'mgi_accession_id' => 'MGI:1923551')
      end

      should 'create a nonexistent one' do
        assert_nil Gene.find_by_marker_symbol 'Trafd1'
        gene = Gene.find_or_create_from_mart_data(
          'marker_symbol' => 'Trafd1',
          'mgi_accession_id' => 'MGI:1923551')
        assert_equal 'Trafd1', gene.marker_symbol
        assert_equal 'MGI:1923551', gene.mgi_accession_id
      end
    end

  end
end
