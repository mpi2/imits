require 'test_helper'

class Old::MiAttemptStatusTest < ActiveSupport::TestCase
  should 'load set correct table name' do
    assert_equal 'emi_status_dict', Old::MiAttemptStatus.table_name
  end
end
