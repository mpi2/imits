# encoding: utf-8

require 'test_helper'

class PhenotypeAttempt::StatusChangerTest < ActiveSupport::TestCase
  context 'PhenotypeAttempt::StatusChanger' do

    def phenotype_attempt
      @phenotype_attempt ||= Factory.build :phenotype_attempt
    end

    should 'not set a status if any of its required statuses conditions are not met as well' do
      phenotype_attempt.number_of_cre_matings_started = 4
      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.phenotype_started = true
      phenotype_attempt.valid?
      assert_equal 'Phenotyping Started', phenotype_attempt.status.name

      phenotype_attempt.number_of_cre_matings_started = 0
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Registered', phenotype_attempt.status.name
    end

    should 'transition through Phenotype Attempt Registered -> Rederivation Started -> ' +
            'Rederivation Complete -> Cre Excision Started -> ' +
            'Cre Excision Complete -> Phenotyping Started -> Phenotyping Complete' do
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Registered', phenotype_attempt.status.name

      phenotype_attempt.rederivation_started = true
      phenotype_attempt.valid?
      assert_equal 'Rederivation Started', phenotype_attempt.status.name

      phenotype_attempt.rederivation_complete = true
      phenotype_attempt.valid?
      assert_equal 'Rederivation Complete', phenotype_attempt.status.name

      phenotype_attempt.number_of_cre_matings_started = 4
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Started', phenotype_attempt.status.name

      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Complete', phenotype_attempt.status.name

      phenotype_attempt.phenotype_started = true
      phenotype_attempt.valid?
      assert_equal 'Phenotyping Started', phenotype_attempt.status.name

      phenotype_attempt.phenotype_complete = true
      phenotype_attempt.valid?
      assert_equal 'Phenotyping Complete', phenotype_attempt.status.name
    end

    should 'transition through Phenotype Attempt Registered -> Cre Excision Started -> Cre Excision Complete' do
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Registered', phenotype_attempt.status.name

      phenotype_attempt.number_of_cre_matings_started = 4
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Started', phenotype_attempt.status.name

      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Complete', phenotype_attempt.status.name
    end

    should 'transition to Aborted if is_active is set, regardless of other statuses' do
      phenotype_attempt.is_active = false

      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name

      phenotype_attempt.rederivation_started = true
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name

      phenotype_attempt.rederivation_complete = true
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name

      phenotype_attempt.number_of_cre_matings_started = 4
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name

      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name

      phenotype_attempt.phenotype_started = true
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name

      phenotype_attempt.phenotype_complete = true
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name
    end

  end
end
