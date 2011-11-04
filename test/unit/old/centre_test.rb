require 'test_helper'

class Old::CentreTest < ActiveSupport::TestCase
  should 'use table per_centre' do
    assert_equal 'per_centre', Old::Centre.table_name
  end

  should 'be read only by default' do
    centre = Old::Centre.find(:first)
    assert_equal true, centre.readonly?
  end
end
