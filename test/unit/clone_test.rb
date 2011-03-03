require 'test_helper'

class CloneTest < ActiveSupport::TestCase
  should 'use table "emi_clone"' do
    assert_equal 'emi_clone', Clone.table_name
  end
end
