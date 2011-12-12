require 'test_helper'

class MiPlan::StatusStampTest < ActiveSupport::TestCase
  context 'MiPlan::StatusStamp' do
    should have_db_column(:mi_plan_id).with_options(:null => false)
    should have_db_column(:status_id).with_options(:null => false)
    should have_db_column(:created_at)

    should belong_to :mi_plan
    should belong_to :status

    should 'have #name proxy' do
      mi_plan_status = MiPlan::Status.first
      assert_equal mi_plan_status.name, MiPlan::StatusStamp.new(:status_id => mi_plan_status.id).name
    end
  end
end
