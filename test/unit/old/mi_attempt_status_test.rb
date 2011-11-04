require 'test_helper'

class Old::MiAttemptStatusTest < ActiveSupport::TestCase
  should 'load set correct table name' do
    assert_equal 'emi_status_dict', Old::MiAttemptStatus.table_name
  end

  should 'be read only by default' do
    record = Old::MiAttemptStatus.find(:first)
    assert_equal true, record.readonly?
  end
end
