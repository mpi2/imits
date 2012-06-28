require 'test_helper'

class MiAttempt::DistributionCentreTest < ActiveSupport::TestCase
  context 'MiAttempt::DistributionCentre' do

    should have_db_column :created_at

    should have_db_column :id
    should have_db_column :start_date
    should have_db_column :end_date
    should_have_db_column :is_distributed_by_emma

    should belong_to :mi_attempt
    should belong_to :centre
    should_belong_to :deposited_material

  end
end
