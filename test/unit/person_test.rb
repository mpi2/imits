require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  should 'use table per_person' do
    assert_equal 'per_person', Person.table_name
  end

  should 'authenticate with correct password' do
    assert_not_nil Person.find_by_user_name('zz99')
    assert_equal Person.find_by_user_name('zz99'), Person.authenticate('zz99', 's3cr31-6a55w0rd')
  end

  should 'not authenticate with incorrect password' do
    assert_nil Person.authenticate('zz99', 'incorrect-password')
  end

  should 'not authenticate with missing user' do
    assert_nil Person.authenticate('missing', 'password')
  end
end
