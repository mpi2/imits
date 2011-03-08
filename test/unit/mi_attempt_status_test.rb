require 'test_helper'

class MiAttemptStatusTest < ActiveSupport::TestCase
  should 'load set correct table name' do
    assert_equal 'emi_status_dict', MiAttemptStatus.table_name
  end
end
