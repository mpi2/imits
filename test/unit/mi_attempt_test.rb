require 'test_helper'

class MiAttemptTest < ActiveSupport::TestCase
  context 'MiAttempt' do
    setup do
      Factory.create :mi_attempt
    end

    should have_db_column(:clone_id).with_options(:null => false)
    should belong_to :clone
    should validate_presence_of :clone
  end
end
