require 'test_helper'

class MiAttemptStatusTest < ActiveSupport::TestCase
  context 'MiAttemptStatus' do

    should have_db_column(:description).with_options(:null => false)
    should validate_presence_of :description
    should validate_uniqueness_of :description

    context 'easy-access constants' do
      should 'include IN_PROGRESS' do
        assert_equal 'In progress', MiAttemptStatus::IN_PROGRESS.description
        assert_true MiAttemptStatus::IN_PROGRESS.frozen?
      end

      should 'include GOOD' do
        assert_equal 'Good', MiAttemptStatus::GOOD.description
        assert_true MiAttemptStatus::GOOD.frozen?
      end
    end

  end
end
