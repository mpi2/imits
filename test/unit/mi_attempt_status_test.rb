require 'test_helper'

class MiAttemptStatusTest < ActiveSupport::TestCase
  context 'MiAttemptStatus' do
    setup do
      Factory.create :mi_attempt_status
    end

    should have_db_column(:description).with_options(:null => false)
    should validate_presence_of :description
  end
end
