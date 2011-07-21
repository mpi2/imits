# encoding: utf-8

require 'test_helper'

class GeneTest < ActiveSupport::TestCase
  context 'Gene' do
    context '(misc. tests)' do
      should have_many :es_cells

      should have_db_column(:marker_symbol).of_type(:string).with_options(:null => false, :limit => 75)
      should have_db_column(:mgi_accession_id).of_type(:string).with_options(:null => true, :limit => 40)

      should validate_presence_of :marker_symbol
      should validate_uniqueness_of :marker_symbol
    end
  end
end
