# encoding: utf-8

require 'test_helper'

class MiAttempt::StatusChangerTest < ActiveSupport::TestCase
  context 'MiAttempt::StatusChanger' do

    context 'when production centre is WTSI' do
      setup do
        @mi_attempt = Factory.create :mi_attempt,
                :production_centre_name => 'WTSI',
                :is_released_from_genotyping => false
        assert_equal 1, @mi_attempt.status_stamps.size
      end

      should 'be Micro-injection in progress if is_released_from_genotyping is not set' do
        assert_equal MiAttemptStatus.micro_injection_in_progress.description, @mi_attempt.status
      end

      should 'transition MI status to Genotype confirmed if is_released_from_genotyping flag is set' do
        @mi_attempt.is_released_from_genotyping = true
        @mi_attempt.save!
        assert_equal MiAttemptStatus.genotype_confirmed.description, @mi_attempt.status
      end

      should 'not add the same status twice' do
        @mi_attempt.is_released_from_genotyping = true
        @mi_attempt.save!
        @mi_attempt.save!
        assert_equal 2, @mi_attempt.status_stamps.size
      end
    end

    context 'when production centre is not WTSI' do
      setup do
        @mi_attempt = Factory.create :mi_attempt,
                :production_centre_name => 'ICS',
                :number_of_het_offspring => nil,
                :number_of_chimeras_with_glt_from_genotyping => nil
        assert_equal 1, @mi_attempt.status_stamps.size
      end

      should 'be Micro-injection in progress if the two fields are nil' do
        assert_equal MiAttemptStatus.micro_injection_in_progress.description, @mi_attempt.status
      end

      should 'be Micro-injection in progress if the two fields are 0' do
        @mi_attempt.number_of_het_offspring = 0
        @mi_attempt.number_of_chimeras_with_glt_from_genotyping = 0
        @mi_attempt.save!
        assert_equal MiAttemptStatus.micro_injection_in_progress.description, @mi_attempt.status
      end

      should 'transition MI status to Genotype confirmed if number_of_het_offspring is non-zero' do
        @mi_attempt.number_of_het_offspring = 1
        @mi_attempt.save!
        assert_equal MiAttemptStatus.genotype_confirmed.description, @mi_attempt.status
      end

      should 'transition MI status to Genotype confirmed if number_of_chimeras_with_glt_from_genotyping is non-zero' do
        @mi_attempt.number_of_chimeras_with_glt_from_genotyping = 1
        @mi_attempt.save!
        assert_equal MiAttemptStatus.genotype_confirmed.description, @mi_attempt.status
      end

      should 'ignore is_released_from_genotyping flag' do
        @mi_attempt.number_of_chimeras_with_glt_from_genotyping = 0
        @mi_attempt.number_of_het_offspring = nil
        @mi_attempt.is_released_from_genotyping = true
        @mi_attempt.save!
        assert_equal MiAttemptStatus.micro_injection_in_progress.description, @mi_attempt.status
      end

      should 'not add the same status twice' do
        @mi_attempt.number_of_het_offspring = 1
        @mi_attempt.save!
        @mi_attempt.save!
        assert_equal 2, @mi_attempt.status_stamps.size
      end
    end

    context 'active flag' do
      context 'when set to false' do
        context 'when production centre is WTSI' do
          should 'set status to aborted, even if is_released_from_gentotyping is true' do
            mi = Factory.create :mi_attempt,
                    :production_centre_name => 'WTSI',
                    :is_released_from_genotyping => true,
                    :is_active => false

            assert_equal MiAttemptStatus.micro_injection_aborted.description, mi.status
          end
        end

        context 'when production centre is not WTSI' do
          should 'set status to aborted, even if genotype confirmed conditions are met' do
            mi = Factory.create :mi_attempt,
                    :production_centre_name => 'ICS',
                    :number_of_het_offspring => 1,
                    :is_active => false

            assert_equal MiAttemptStatus.micro_injection_aborted.description, mi.status
          end
        end
      end

      context 'when was false (and status was aborted) and is set to true' do
        should 'add an in-progress status' do
          mi = Factory.create :mi_attempt,
                  :production_centre_name => 'ICS',
                  :is_active => false

          mi.is_active = true
          mi.save!

          assert_equal MiAttemptStatus.micro_injection_in_progress.description, mi.status
        end

        should 're-evaluate status based on rules and set to confirmed' do
          mi = Factory.create :mi_attempt,
                  :production_centre_name => 'WTSI',
                  :is_released_from_genotyping => true,
                  :is_active => false

          mi.is_active = true
          mi.save!

          assert_equal MiAttemptStatus.genotype_confirmed.description, mi.status
        end
      end
    end

    # Only testing non-WTSI statuses since WTSI should eventually accept same
    # status changing rules

    should 'not add an in-progress status if it is initially another status' do
      mi = Factory.create :mi_attempt,
              :production_centre_name => 'ICS',
              :number_of_het_offspring => 1,
              :is_active => false
      mi.update_attributes!(:is_active => true)

      assert_equal MiAttemptStatus.micro_injection_aborted.description, mi.status_stamps[0].description
    end

    should 'avoid adding the same status twice consecutively' do
      mi = Factory.create :mi_attempt,
              :production_centre_name => 'ICS'
      mi.save!
      mi.update_attributes!(:number_of_het_offspring => 1)
      mi.save!
      mi.update_attributes!(:is_active => false)
      mi.save!

      expected_statuses = [
        MiAttemptStatus.micro_injection_in_progress,
        MiAttemptStatus.genotype_confirmed,
        MiAttemptStatus.micro_injection_aborted
      ].map(&:description)

      assert_equal expected_statuses, mi.status_stamps.map(&:description)
    end
  end
end
