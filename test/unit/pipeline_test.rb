require 'test_helper'

class PipelineTest < ActiveSupport::TestCase
  context 'Pipeline' do
    setup do
      Factory.create :pipeline
    end

    context 'DB indices' do
      setup do
        @pipeline = Factory.build :pipeline
      end

      should 'include uniqueness on name' do
        @pipeline.name = 'EUCOMM'
        assert_raise ActiveRecord::RecordNotUnique do
          @pipeline.save!(:validate => false)
        end
      end

      should 'include not null on name' do
        @pipeline.name = nil
        assert_raise ActiveRecord::StatementInvalid do
          @pipeline.save!(:validate => false)
        end
      end

      should 'include not null on description' do
        @pipeline.description = nil
        assert_raise ActiveRecord::StatementInvalid do
          @pipeline.save!(:validate => false)
        end
      end
    end

    should validate_presence_of :name
    should validate_presence_of :description

    should validate_uniqueness_of :name
  end
end
