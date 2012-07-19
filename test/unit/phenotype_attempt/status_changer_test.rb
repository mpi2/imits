# encoding: utf-8

require 'test_helper'

class PhenotypeAttempt::StatusChangerTest < ActiveSupport::TestCase
  context 'PhenotypeAttempt::StatusChanger' do

    def phenotype_attempt
      @phenotype_attempt ||= Factory.build :phenotype_attempt
    end

    should 'not set a status if any of its required statuses conditions are not met as well' do
      phenotype_attempt.deleter_strain = DeleterStrain.first
      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.mouse_allele_type = 'b'
      phenotype_attempt.phenotyping_started = true
      phenotype_attempt.valid?
      assert_equal 'Phenotyping Started', phenotype_attempt.status.name

      phenotype_attempt.deleter_strain = nil
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

      phenotype_attempt.deleter_strain = DeleterStrain.first
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Started', phenotype_attempt.status.name

      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.mouse_allele_type = 'b'
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Complete', phenotype_attempt.status.name

      phenotype_attempt.phenotyping_started = true
      phenotype_attempt.valid?
      assert_equal 'Phenotyping Started', phenotype_attempt.status.name

      phenotype_attempt.phenotyping_complete = true
      phenotype_attempt.valid?
      assert_equal 'Phenotyping Complete', phenotype_attempt.status.name
    end

    should 'transition through Phenotype Attempt Registered -> Cre Excision Started -> Cre Excision Complete with mouse_allele_type of "b"' do
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Registered', phenotype_attempt.status.name

      phenotype_attempt.deleter_strain = DeleterStrain.first
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Started', phenotype_attempt.status.name

      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.mouse_allele_type = 'b'
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Complete', phenotype_attempt.status.name
    end

    should 'transition through Phenotype Attempt Registered -> Cre Excision Started -> Cre Excision Complete with mouse_allele_type of ".1"' do
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Registered', phenotype_attempt.status.name

      phenotype_attempt.deleter_strain = DeleterStrain.first
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Started', phenotype_attempt.status.name

      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.mouse_allele_type = '.1'
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

      phenotype_attempt.deleter_strain = DeleterStrain.first
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name

      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name

      phenotype_attempt.phenotyping_started = true
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name

      phenotype_attempt.phenotyping_complete = true
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name
    end

    should 'transition to Cre Excision Complete if mouse_allele_type is set to "b"' do
      phenotype_attempt.mouse_allele_type = 'b'
      phenotype_attempt.deleter_strain = DeleterStrain.first
      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Complete', phenotype_attempt.status.name
    end

    should 'transition to Cre Excision Complete if mouse_allele_type is set to ".1"' do
      phenotype_attempt.mouse_allele_type = '.1'
      phenotype_attempt.deleter_strain = DeleterStrain.first
      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Complete', phenotype_attempt.status.name
    end


  end
end
