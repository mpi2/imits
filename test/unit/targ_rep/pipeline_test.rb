require 'test_helper'

class TargRep::PipelineTest < ActiveSupport::TestCase
  context 'TargRep::Pipeline' do
    setup do
      Factory.create :pipeline
    end

    should have_many(:targeting_vectors)
    should have_many(:es_cells)

    should have_db_column(:name).with_options(:null => false)
    should have_db_index(:name).unique(true)
    should validate_presence_of :name
    should validate_uniqueness_of :name

    should have_db_column(:description).with_options(:null => true)

    context "Pipeline with empty attributes" do
      pipeline = Factory.build(:invalid_pipeline)
      should "not be saved" do
        assert !pipeline.valid?, "Pipeline validates an empty entry"
        assert !pipeline.save, "Pipeline validates the creation of an empty entry"
      end
    end
  end
end
