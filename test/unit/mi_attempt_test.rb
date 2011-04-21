require 'test_helper'

class MiAttemptTest < ActiveSupport::TestCase
  context 'MiAttempt' do
    setup do
      @mi_attempt = Factory.create :mi_attempt
    end

    should have_db_column(:clone_id).with_options(:null => false)
    should belong_to :clone
    should validate_presence_of :clone

    should have_db_column :centre_id
    should belong_to :centre

    should have_db_column :distribution_centre_id
    should belong_to :distribution_centre

    should have_db_column(:mi_attempt_status_id).with_options(:null => false)
    should belong_to :mi_attempt_status

    should validate_presence_of :mi_attempt_status

    should 'set mi_attempt_status to "In progress" by default' do
      assert_equal 'In progress',
              Factory.build(:mi_attempt).mi_attempt_status.description
    end

    should 'not overwrite status if it is set explicitly' do
      mi_attempt = Factory.create(:mi_attempt, :mi_attempt_status => MiAttemptStatus.good)
      assert_equal 'Good', mi_attempt.mi_attempt_status.description
    end

  end
end
