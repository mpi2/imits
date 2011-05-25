require 'test_helper'

class UserTest < ActiveSupport::TestCase
  context 'User' do

    subject { Factory.create :user }

    should 'have accessible attributes' do
      assert_include User.accessible_attributes, :email
      assert_include User.accessible_attributes, :password
      assert_include User.accessible_attributes, :password_confirmation
      assert_include User.accessible_attributes, :remember_me
    end

    context 'remember_me' do
      should 'be true by default' do
        assert_equal true, subject.remember_me
      end
    end

  end
end
