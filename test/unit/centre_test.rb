require 'test_helper'

class CentreTest < ActiveSupport::TestCase
  should 'use table per_centre' do
    assert_equal 'per_centre', Centre.table_name
  end
end
