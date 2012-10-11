# encoding: utf-8

require 'test_helper'

class MiAttempt::StatusTest < ActiveSupport::TestCase
  context 'MiAttempt::Status' do

    should have_db_column(:name).with_options(:null => false)
    should have_db_index(:name).unique(true)

    should validate_presence_of :name
    should validate_uniqueness_of :name

    should have_many :status_stamps
    should have_many(:mi_attempts).through(:status_stamps)

    context 'easy-access methods' do
      should 'include in_progress' do
        assert_equal 'Micro-injection in progress', MiAttempt::Status.micro_injection_in_progress.name
        assert_true MiAttempt::Status.micro_injection_in_progress.frozen?
      end

      should 'include genotype_confirmed' do
        assert_equal 'Genotype confirmed', MiAttempt::Status.genotype_confirmed.name
        assert_true MiAttempt::Status.genotype_confirmed.frozen?
      end

      should 'include aborted' do
        assert_equal 'Micro-injection aborted', MiAttempt::Status.micro_injection_aborted.name
        assert_true MiAttempt::Status.micro_injection_aborted.frozen?
      end

      should 'include chimeras' do
        assert_equal 'Chimeras obtained', MiAttempt::Status.chimeras_obtained.name
        assert_true MiAttempt::Status.chimeras_obtained.frozen?
      end
    end

    should 'include StatusInterface' do
      assert_include MiAttempt::Status.ancestors, StatusInterface
    end

  end
end
