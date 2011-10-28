# encoding: utf-8

require 'test_helper'

class MiPlanStatusTest < ActiveSupport::TestCase
  should validate_presence_of :name
  should validate_uniqueness_of :name

  should have_db_column(:name).with_options(:limit => 50, :null => false)
  should have_db_index(:name).unique(true)

  should have_db_column(:description).with_options(:limit => 255)

  should have_db_column(:order_by)

  should 'have ::[] lookup shortcut' do
    assert_equal MiPlanStatus.find_by_name!('Interest'), MiPlanStatus['Interest']
    assert_equal MiPlanStatus.find_by_name!('Assigned'), MiPlanStatus['Assigned']
    assert_equal MiPlanStatus.find_by_name!('Conflict'), MiPlanStatus[:Conflict]
  end

  should 'have ::all_non_assigned' do
    expected = [
      'Interest',
      'Conflict',
      'Declined - GLT Mouse',
      'Declined - MI Attempt',
      'Declined - Conflict',
      'Inactive'
    ].sort
    assert_equal expected, MiPlanStatus.all_non_assigned.map(&:name).sort
  end
end
