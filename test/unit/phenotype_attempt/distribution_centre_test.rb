require 'test_helper'

class PhenotypeAttempt::DistributionCentreTest < ActiveSupport::TestCase
  context 'PhenotypeAttempt::DistributionCentre' do

    should have_db_column :created_at

    should have_db_column :id
    should have_db_column :start_date
    should have_db_column :end_date
    should_have_db_column :is_distributed_by_emma

    should belong_to :phenotype_attempt
    should belong_to :centre
    should_belong_to :deposited_material

  end
end
