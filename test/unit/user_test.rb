require 'test_helper'

class UserTest < ActiveSupport::TestCase
  context 'User' do

    subject { Factory.create :user }

    should 'have accessible attributes' do
      assert_include User.accessible_attributes, :email
      assert_include User.accessible_attributes, :password
      assert_include User.accessible_attributes, :password_confirmation
      assert_include User.accessible_attributes, :remember_me
      assert_include User.accessible_attributes, :production_centre
      assert_include User.accessible_attributes, :production_centre_id
      assert_include User.accessible_attributes, :name
    end

    should 'have unique index on email' do
      assert_should have_db_index(:email).unique(true)
    end

    should 'belong to production centre' do
      assert_should belong_to :production_centre
    end

    should 'have production_centre_id field' do
      assert_should have_db_column(:production_centre_id).with_options(:null => false)
    end

    context 'remember_me' do
      should 'be true by default' do
        assert_equal true, subject.remember_me
      end
    end

    should 'have admin users' do
      assert_true Factory.create(:user, :email => 'vvi@sanger.ac.uk').admin?
      assert_false Factory.create(:user).admin?
    end

  end
end
