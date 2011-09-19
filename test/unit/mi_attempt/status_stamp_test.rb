require 'test_helper'

class MiAttempt::StatusStampTest < ActiveSupport::TestCase
  context 'MiAttempt::StatusStamp' do

    should have_db_column :created_at

    should have_db_column :id

    should belong_to :mi_attempt
    should belong_to :mi_attempt_status

    should 'have #description proxy' do
      stamp = MiAttempt::StatusStamp.new(:mi_attempt_status => MiAttemptStatus.micro_injection_aborted)
      assert_equal MiAttemptStatus.micro_injection_aborted.description, stamp.description
    end
  end
end
