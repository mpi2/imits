# encoding: utf-8

require 'test_helper'

class Old::UserTest < ActiveSupport::TestCase
  context 'Old::User' do

    should 'use table per_person' do
      assert_equal 'per_person', Old::User.table_name
    end

    should 'be read only by default' do
      record = Old::User.find(:first)
      assert_equal true, record.readonly?
    end

    should 'authenticate with correct password' do
      expected = Old::User.find_by_user_name('aq2')
      assert_not_nil expected
      assert_equal expected, Old::User.authenticate(expected.user_name, 'password')
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

    should 'belong to old centre' do
      assert_equal Old::Centre.find_by_name('WTSI'), Old::User.find_by_user_name('aq2').centre
    end

  end
end
