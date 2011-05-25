require 'test_helper'

class UserTest < ActiveSupport::TestCase
  context 'User' do
    subject { Factory.create :user }

    should 'have accessible attributes' do
      expected = %w{email password password_confirmation}
      attrs_not_in_both = (Set.new(User.accessible_attributes) ^ Set.new(expected))
      assert_empty attrs_not_in_both, "Accessible attributes error: #{attrs_not_in_both.inspect}"
    end

    should 'default remember_me to true' do
      assert_equal true, subject.remember_me
    end
  end
end
