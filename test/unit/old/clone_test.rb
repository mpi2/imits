require 'test_helper'

class Old::CloneTest < ActiveSupport::TestCase
  should 'use table "emi_clone"' do
    assert_equal 'emi_clone', Old::Clone.table_name
  end
end
