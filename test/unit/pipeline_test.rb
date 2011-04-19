require 'test_helper'

class PipelineTest < ActiveSupport::TestCase
  context 'Pipeline' do
    setup do
      Factory.create :pipeline
    end

    should validate_presence_of :name
    should validate_presence_of :description

    should validate_uniqueness_of :name
  end
end
