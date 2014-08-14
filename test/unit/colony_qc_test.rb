require 'test_helper'

class ColonyQcTest < ActiveSupport::TestCase
  context 'ColonyQc' do
    should validate_presence_of :colony_id

    should belong_to :colony

    # basic creation should work

    # basic creation should set qc fields to 'na'

    # creation with qc values of 'pass' or 'fail' or 'na' should work
  end
end
