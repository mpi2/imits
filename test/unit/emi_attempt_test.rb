require 'test_helper'

class EmiAttemptTest < ActiveSupport::TestCase
  should 'use table "emi_attempt"' do
    assert_equal 'emi_attempt', EmiAttempt.table_name
  end
end
