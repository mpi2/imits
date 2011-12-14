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

    context 'Rederivation Complete' do
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

    context 'Cre Excision Started' do
      should 'be set if number_of_cre_matings_started is > 0 and Rederivation Complete conditions are met' do
        phenotype_attempt.rederivation_started = true
        phenotype_attempt.rederivation_complete = true
        phenotype_attempt.number_of_cre_matings_started = 4
        phenotype_attempt.valid?
        assert_equal 'Cre Excision Started', phenotype_attempt.status.name
      end
    end

    context 'Cre Excision Complete' do
      should 'be set if number_of_cre_matings_successful is > 0 and Cre Excision Started conditions are met' do
        phenotype_attempt.rederivation_started = true
        phenotype_attempt.rederivation_complete = true
        phenotype_attempt.number_of_cre_matings_started = 4
        phenotype_attempt.number_of_cre_matings_successful = 2
        phenotype_attempt.valid?
        assert_equal 'Cre Excision Complete', phenotype_attempt.status.name
      end

      should 'not be set if number_of_cre_matings_successful is > 0 but Cre Excision Started conditions are NOT met' do
        phenotype_attempt.rederivation_started = true
        phenotype_attempt.rederivation_complete = true
        phenotype_attempt.number_of_cre_matings_started = 0
        phenotype_attempt.number_of_cre_matings_successful = 2
        phenotype_attempt.valid?
        assert_not_equal 'Cre Excision Complete', phenotype_attempt.status.name
      end
    end

  end
end
