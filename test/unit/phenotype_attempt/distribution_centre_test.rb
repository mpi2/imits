require 'test_helper'

class PhenotypeAttempt::DistributionCentreTest < ActiveSupport::TestCase
  context 'PhenotypeAttempt::DistributionCentre' do

    should have_db_column :created_at

    should have_db_column :id
    should have_db_column :start_date
    should have_db_column :end_date
    should have_db_column :is_distributed_by_emma

    should belong_to :phenotype_attempt
    should belong_to :centre
    should belong_to :deposited_material

    context '#centre_name virtual attribute' do
      should 'populate centre_id before validation' do
        phenotype_attempt_distribution_centre = Factory.create :phenotype_attempt_distribution_centre
        distribution_centre_id = phenotype_attempt_distribution_centre.centre_id
        phenotype_attempt_distribution_centre.centre_id = nil

        phenotype_attempt_distribution_centre.valid?
        assert_equal phenotype_attempt_distribution_centre.centre_id, distribution_centre_id
      end
    end

    context '#deposited_material_name virtual attribute' do
      should 'populate deposited_material_id before validation' do
        phenotype_attempt_distribution_centre = Factory.create :phenotype_attempt_distribution_centre
        deposited_material_id = phenotype_attempt_distribution_centre.deposited_material_id
        phenotype_attempt_distribution_centre.deposited_material_id = nil

        phenotype_attempt_distribution_centre.valid?
        assert_equal phenotype_attempt_distribution_centre.deposited_material_id, deposited_material_id
      end
    end

  end
end
