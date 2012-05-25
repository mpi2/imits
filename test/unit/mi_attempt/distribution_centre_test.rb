require 'test_helper'

class MiAttempt::DistributionCentreTest < ActiveSupport::TestCase
  context 'MiAttempt::DistributionCentre' do

    should have_db_column :created_at

    should have_db_column :id
    should have_db_column :start_date
    should have_db_column :end_date

    should belong_to :mi_attempt
    should belong_to :centre
    should_belong_to :deposited_material

    should 'exist if MiAttempt status is Genotype confirmed' do
      mi = Factory.create :mi_attempt_genotype_confirmed
      assert_equal 1, mi.distribution_centres.length
    end

  end
end
