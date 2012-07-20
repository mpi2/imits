require 'test_helper'

class MiAttempt::DistributionCentreTest < ActiveSupport::TestCase
  context 'MiAttempt::DistributionCentre' do

    should have_db_column :created_at

    should have_db_column :id
    should have_db_column :start_date
    should have_db_column :end_date
    should have_db_column :is_distributed_by_emma

    should belong_to :mi_attempt
    should belong_to :centre
    should belong_to :deposited_material

    context '#centre_name virtual attribute' do
      should 'populate centre_id before validation' do
        mi_attempt_distribution_centre = Factory.create :mi_attempt_distribution_centre
        distribution_centre_id = mi_attempt_distribution_centre.centre_id
        mi_attempt_distribution_centre.centre_id = nil

        mi_attempt_distribution_centre.valid?
        assert_equal mi_attempt_distribution_centre.centre_id, distribution_centre_id
      end
    end

    context '#deposited_material_name virtual attribute' do
      should 'populate deposited_material_id before validation' do
        mi_attempt_distribution_centre = Factory.create :mi_attempt_distribution_centre
        deposited_material_id = mi_attempt_distribution_centre.deposited_material_id
        mi_attempt_distribution_centre.deposited_material_id = nil

        mi_attempt_distribution_centre.valid?
        assert_equal mi_attempt_distribution_centre.deposited_material_id, deposited_material_id
      end
    end

  end
end
