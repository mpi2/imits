# encoding: utf-8

require 'test_helper'

class MiAttempt::StatusChangerTest < ActiveSupport::TestCase
  context 'MiAttempt::StatusChanger' do

    context 'when production centre is WTSI' do
      setup do
        @mi_attempt = Factory.create :mi_attempt,
                :production_centre_name => 'WTSI',
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
        @mi_attempt = Factory.create :mi_attempt,
                :production_centre_name => 'ICS',
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
      es_cell = Factory.create :es_cell_EPD0343_1_H06
      mi_attempt = es_cell.mi_attempts.first
      assert_equal 'WTSI', mi_attempt.production_centre_name
      assert_equal MiAttemptStatus.micro_injection_in_progress, mi_attempt.mi_attempt_status
      mi_attempt.is_released_from_genotyping = true
      mi_attempt.save!

      assert_equal MiAttemptStatus.genotype_confirmed, mi_attempt.mi_attempt_status
    end

    context 'active flag' do
      context 'when set to false' do
        context 'when production centre is WTSI' do
          should 'set status to aborted, even if is_released_from_gentotyping is true' do
            mi = Factory.create :mi_attempt,
                    :production_centre_name => 'WTSI',
                    :is_released_from_genotyping => true
            mi.is_active = false
            mi.save!

            assert_equal MiAttemptStatus.micro_injection_aborted, mi.mi_attempt_status
          end
        end

        context 'when production centre is not WTSI' do
          should 'set status to aborted, even if genotype confirmed conditions are met' do
            mi = Factory.create :mi_attempt,
                    :production_centre_name => 'ICS',
                    :number_of_het_offspring => 1
            mi.is_active = false
            mi.save!

            assert_equal MiAttemptStatus.micro_injection_aborted, mi.mi_attempt_status
          end
        end
      end

      context 'when was false (and status was aborted) and is set to true' do
        should 'set status to in progress' do
          mi = Factory.create :mi_attempt,
                  :production_centre_name => 'ICS'
          mi.is_active = false
          mi.save!

          mi.is_active = true
          mi.save!

          assert_equal MiAttemptStatus.micro_injection_in_progress, mi.mi_attempt_status
        end

        should 're-evaluate status based on rules and set to confirmed' do
          mi = Factory.create :mi_attempt,
                  :production_centre_name => 'WTSI',
                  :is_released_from_genotyping => true
          mi.is_active = false
          mi.save!

          mi.is_active = true
          mi.save!

          assert_equal MiAttemptStatus.genotype_confirmed, mi.mi_attempt_status
        end
      end
    end

  end
end
