require 'test_helper'

class CloneTest < ActiveSupport::TestCase
  setup do
    Factory.create :clone
  end

  context 'Clone' do
    should belong_to :pipeline

    should have_db_column(:clone_name).with_options(:null => false)
    should have_db_index(:clone_name).unique(true)
    should validate_presence_of :clone_name
    should validate_uniqueness_of :clone_name

    should have_db_column(:marker_symbol).with_options(:null => false)
    should validate_presence_of :marker_symbol

    should have_db_column(:allele_name_superscript).with_options(:null => false)
    should validate_presence_of :allele_name_superscript

    should have_db_column(:pipeline_id).with_options(:null => false)
    should validate_presence_of :pipeline
  end
end
