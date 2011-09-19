# encoding: utf-8

require 'test_helper'

class MiAttemptStatusTest < ActiveSupport::TestCase
  context 'MiAttemptStatus' do

    should have_db_column(:description).with_options(:null => false)
    should have_db_index(:description).unique(true)
    should validate_presence_of :description
    should validate_uniqueness_of :description

    assert_should have_many :status_stamps
    assert_should have_many(:mi_attempts).through(:status_stamps)

    context 'easy-access methods' do
      should 'include in_progress' do
        assert_equal 'Micro-injection in progress', MiAttemptStatus.micro_injection_in_progress.description
        assert_true MiAttemptStatus.micro_injection_in_progress.frozen?
      end

      should 'include genotype_confirmed' do
        assert_equal 'Genotype confirmed', MiAttemptStatus.genotype_confirmed.description
        assert_true MiAttemptStatus.genotype_confirmed.frozen?
      end

      should 'include aborted' do
        assert_equal 'Micro-injection aborted', MiAttemptStatus.micro_injection_aborted.description
        assert_true MiAttemptStatus.micro_injection_aborted.frozen?
      end
    end

  end
end
