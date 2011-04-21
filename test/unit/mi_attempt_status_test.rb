require 'test_helper'

class MiAttemptStatusTest < ActiveSupport::TestCase
  context 'MiAttemptStatus' do

    should have_db_column(:description).with_options(:null => false)
    should have_db_index(:description).unique(true)
    should validate_presence_of :description
    should validate_uniqueness_of :description

    context 'easy-access methods' do
      should 'include in_progress' do
        assert_equal 'In progress', MiAttemptStatus.in_progress.description
        assert_true MiAttemptStatus.in_progress.frozen?
      end

      should 'include GOOD' do
        assert_equal 'Good', MiAttemptStatus.good.description
        assert_true MiAttemptStatus.good.frozen?
      end
    end

  end
end
