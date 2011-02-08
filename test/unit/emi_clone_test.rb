require 'test_helper'

class EmiCloneTest < ActiveSupport::TestCase
  should 'use table "emi_clone"' do
    assert_equal 'emi_clone', EmiClone.table_name
  end
end
