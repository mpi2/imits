require 'test_helper'

class ApplicationModel::BelongsToMiPlanTest < ActiveSupport::TestCase
  context 'ApplicationModel::BelongsToMiPlan' do

    context '#production_centre_name' do
      context 'if not set' do
        should 'read from mi_attempt if exists and is set else from mi_plan else be nil'
      end

      should 'return what has been explicitly assigned regardless of mi_plan or mi_attempt existence'
    end

  end
end
