# encoding: utf-8

require 'test_helper'

class MiAttempt::StatusChangerTest < ActiveSupport::TestCase
  context 'MiAttempt::StatusChanger' do

    context 'when production centre is WTSI' do
      setup do
        @mi_attempt = Factory.build :mi_attempt,
                :production_centre => Centre.find_by_name('WTSI'),
                :mi_attempt_status => MiAttemptStatus.micro_injection_in_progress
      end

      should 'not affect status if is_released_from_genotyping is not set' do
        @mi_attempt.is_released_from_genotyping = false
        @mi_attempt.change_status
        assert_equal MiAttemptStatus.micro_injection_in_progress, @mi_attempt.mi_attempt_status
      end

      should 'transition MI status to Genotype confirmed if is_released_from_genotyping flag is set' do
        @mi_attempt.is_released_from_genotyping = true
        @mi_attempt.change_status
        assert_equal MiAttemptStatus.genotype_confirmed, @mi_attempt.mi_attempt_status
      end
    end

    context 'when production centre is not WTSI' do
      setup do
        @mi_attempt = Factory.build :mi_attempt,
                :production_centre => Centre.find_by_name('ICS'),
                :mi_attempt_status => MiAttemptStatus.micro_injection_in_progress
      end

      should 'not affect status if the two fields are nil' do
        @mi_attempt.number_of_het_offspring = nil
        @mi_attempt.number_of_chimeras_with_glt_from_genotyping = nil
        @mi_attempt.change_status
        assert_equal MiAttemptStatus.micro_injection_in_progress, @mi_attempt.mi_attempt_status
      end

      should 'not affect status if the two fields are 0' do
        @mi_attempt.number_of_het_offspring = 0
        @mi_attempt.number_of_chimeras_with_glt_from_genotyping = 0
        @mi_attempt.change_status
        assert_equal MiAttemptStatus.micro_injection_in_progress, @mi_attempt.mi_attempt_status
      end

      should 'transition MI status to Genotype confirmed if number_of_het_offspring is non-zero' do
        @mi_attempt.number_of_het_offspring = 1
        @mi_attempt.change_status
        assert_equal MiAttemptStatus.genotype_confirmed, @mi_attempt.mi_attempt_status
      end

      should 'transition MI status to Genotype confirmed if number_of_chimeras_with_glt_from_genotyping is non-zero' do
        @mi_attempt.number_of_chimeras_with_glt_from_genotyping = 1
        @mi_attempt.change_status
        assert_equal MiAttemptStatus.genotype_confirmed, @mi_attempt.mi_attempt_status
      end

      should 'ignore is_released_from_genotyping flag' do
        @mi_attempt.number_of_chimeras_with_glt_from_genotyping = 0
        @mi_attempt.number_of_het_offspring = nil
        @mi_attempt.is_released_from_genotyping = true
        @mi_attempt.change_status
        assert_equal MiAttemptStatus.micro_injection_in_progress, @mi_attempt.mi_attempt_status
      end
    end

    should 'be invoked as a before_save filter' do
      clone = Factory.create :clone_EPD0343_1_H06
      mi_attempt = clone.mi_attempts.first
      assert_equal 'WTSI', mi_attempt.production_centre.name
      assert_equal MiAttemptStatus.micro_injection_in_progress, mi_attempt.mi_attempt_status
      mi_attempt.is_released_from_genotyping = true
      mi_attempt.save!

      assert_equal MiAttemptStatus.genotype_confirmed, mi_attempt.mi_attempt_status
    end
  end

end
