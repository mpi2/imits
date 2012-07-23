require 'test_helper'

class MiAttempt::StatusStampTest < ActiveSupport::TestCase
  context 'MiAttempt::StatusStamp' do

    should have_db_column :created_at

    should have_db_column :id

    should belong_to :mi_attempt
    should belong_to :status

    should 'have #name proxy' do
      stamp = MiAttempt::StatusStamp.new(:status => MiAttempt::Status.micro_injection_aborted)
      assert_equal MiAttempt::Status.micro_injection_aborted.name, stamp.name
    end

    should 'have #status proxy' do
      stamp = MiAttempt::StatusStamp.new(:status => MiAttempt::Status.micro_injection_aborted)
      assert_equal MiAttempt::Status.micro_injection_aborted, stamp.status
    end
  end
end
