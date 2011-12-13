# encoding: utf-8

require 'test_helper'

class PhenotypeAttempt::StatusChangerTest < ActiveSupport::TestCase
  context 'PhenotypeAttempt::StatusChanger' do

    def phenotype_attempt
      @phenotype_attempt ||= Factory.build :phenotype_attempt
    end

    should 'set default status to Registered' do
      phenotype_attempt.valid?
      assert_equal 'Registered', phenotype_attempt.status.name
    end

    should 'set status to Rederivation Started if its flag is set' do
      phenotype_attempt.rederivation_started = true
      phenotype_attempt.valid?
      assert_equal 'Rederivation Started', phenotype_attempt.status.name
    end

    context 'Rederivation Completed' do
      should 'be set if both rederivation flags are set' do
        phenotype_attempt.rederivation_started = true
        phenotype_attempt.rederivation_complete = true
        phenotype_attempt.valid?
        assert_equal 'Rederivation Complete', phenotype_attempt.status.name
      end

      should 'not be set if both rederivation flags are not set' do
        phenotype_attempt.rederivation_started = true
        phenotype_attempt.rederivation_complete = false
        phenotype_attempt.valid?
        assert_not_equal 'Rederivation Complete', phenotype_attempt.status.name

        phenotype_attempt.rederivation_started = false
        phenotype_attempt.rederivation_complete = true
        phenotype_attempt.valid?
        assert_not_equal 'Rederivation Complete', phenotype_attempt.status.name
      end
    end

  end
end
