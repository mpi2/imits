require 'test_helper'

class PipelineTest < ActiveSupport::TestCase
  context 'Pipeline' do
    setup do
      Factory.create :pipeline
    end

    should have_db_column(:name).with_options(:null => false)
    should have_db_index(:name).unique(true)
    should validate_presence_of :name
    should validate_uniqueness_of :name

    should have_db_column(:description).with_options(:null => false)
    should validate_presence_of :description
  end
end
