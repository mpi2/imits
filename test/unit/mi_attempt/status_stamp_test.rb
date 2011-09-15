require 'test_helper'

class MiAttempt::StatusStampTest < ActiveSupport::TestCase
  context 'MiAttempt::StatusStamp' do

    should have_db_column :created_at
    should have_db_index([:mi_attempt_id, :mi_attempt_status_id]).unique(true)

    should belong_to :mi_attempt
    should belong_to :mi_attempt_status
  end
end
