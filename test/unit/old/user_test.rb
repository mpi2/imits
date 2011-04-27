# encoding: utf-8

require 'test_helper'

class Old::UserTest < ActiveSupport::TestCase
  should 'use table per_person' do
    assert_equal 'per_person', Old::User.table_name
  end

  should 'be read only by default' do
    record = Old::User.find(:first)
    assert_equal true, record.readonly?
  end

  should 'authenticate with correct password' do
    assert_not_nil Old::User.find_by_user_name('rrs')
    assert_equal Old::User.find_by_user_name('rrs'), Old::User.authenticate('rrs', 'password')
  end

  should 'not authenticate with incorrect password' do
    assert_nil Old::User.authenticate('rrs', 'incorrect-password')
  end

  should 'not authenticate with missing user' do
    assert_nil Old::User.authenticate('missing', 'password')
  end

  should 'have #full_name' do
    assert_equal 'Ramiro Ramirez-Solis', Old::User.find_by_user_name('rrs').full_name
  end
end
