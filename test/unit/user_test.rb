require 'test_helper'

class UserTest < ActiveSupport::TestCase
  should 'use table per_person' do
    assert_equal 'per_person', User.table_name
  end

  should 'authenticate with correct password' do
    assert_not_nil User.find_by_user_name('zz99')
    assert_equal User.find_by_user_name('zz99'), User.authenticate('zz99', 's3cr31-6a55w0rd')
  end

  should 'not authenticate with incorrect password' do
    assert_nil User.authenticate('zz99', 'incorrect-password')
  end

  should 'not authenticate with missing user' do
    assert_nil User.authenticate('missing', 'password')
  end
end
