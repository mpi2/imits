# encoding: utf-8

require 'test_helper'

class MiAttempt::StatusManagementTest < ActiveSupport::TestCase
  context 'MiAttempt::StatusManagement' do

    context 'status, when production centre is WTSI' do
      setup do
        @mi_attempt = Factory.create :mi_attempt2,
                :mi_plan => bash_wtsi_cbx1_plan(:force_assignment => true),
                :is_released_from_genotyping => false
      end

      should 'be Micro-injection in progress if is_released_from_genotyping is not set' do
        assert_equal MiAttempt::Status.micro_injection_in_progress, @mi_attempt.status
      end

      should 'transition MI status to Genotype confirmed if is_released_from_genotyping flag is set' do
        @mi_attempt.is_released_from_genotyping = true
        @mi_attempt.total_male_chimeras = 1
        @mi_attempt.save!
        assert_equal MiAttempt::Status.genotype_confirmed, @mi_attempt.status
      end

      should 'not add the same status twice' do
        @mi_attempt.is_released_from_genotyping = true
        @mi_attempt.total_male_chimeras = 1
        @mi_attempt.save!
        @mi_attempt.save!
        assert_equal 3, @mi_attempt.status_stamps.size
      end
    end

    context 'status, when production centre is not WTSI' do
      setup do
        @mi_attempt = Factory.create :mi_attempt2,
                :mi_plan => TestDummy.mi_plan('BaSH', 'ICS', :force_assignment => true),
                :number_of_het_offspring => nil,
                :number_of_chimeras_with_glt_from_genotyping => nil
      end

      should 'be Micro-injection in progress if the two fields are nil' do
        assert_equal MiAttempt::Status.micro_injection_in_progress, @mi_attempt.status
      end

      should 'be Chimeras obtained if the two GC fields are 0' do
        @mi_attempt.total_male_chimeras = 1
        @mi_attempt.number_of_het_offspring = 0
        @mi_attempt.number_of_chimeras_with_glt_from_genotyping = 0
        @mi_attempt.save!
        assert_equal MiAttempt::Status.chimeras_obtained, @mi_attempt.status
      end

      should 'be Chimeras obtained if the two GC fields are nil' do
        @mi_attempt.total_male_chimeras = 1
        @mi_attempt.number_of_het_offspring = nil
        @mi_attempt.number_of_chimeras_with_glt_from_genotyping = nil
        @mi_attempt.save!
        assert_equal MiAttempt::Status.chimeras_obtained, @mi_attempt.status
      end

      should 'transition MI status to Genotype confirmed if number_of_het_offspring is non-zero' do
        @mi_attempt.total_male_chimeras = 1
        @mi_attempt.number_of_het_offspring = 1
        @mi_attempt.save!
        assert_equal MiAttempt::Status.genotype_confirmed, @mi_attempt.status
      end

      should 'transition MI status to Genotype confirmed if number_of_chimeras_with_glt_from_genotyping is non-zero' do
        @mi_attempt.total_male_chimeras = 1
        @mi_attempt.number_of_chimeras_with_glt_from_genotyping = 1
        @mi_attempt.save!
        assert_equal MiAttempt::Status.genotype_confirmed, @mi_attempt.status
      end

      should 'transition MI status to Chimeras obtained if total_male_chimeras is greater than zero and MI is active' do
        @mi_attempt.total_male_chimeras = 1
        @mi_attempt.is_active = true
        @mi_attempt.save!
        assert_equal MiAttempt::Status.chimeras_obtained, @mi_attempt.status
      end

      should 'not transition MI status to Chimeras obtained if total_male_chimeras is greater than zero and MI is not active' do
        @mi_attempt.total_male_chimeras = 1
        @mi_attempt.is_active = false
        @mi_attempt.save!
        assert_not_equal MiAttempt::Status.chimeras_obtained, @mi_attempt.status
        assert_equal MiAttempt::Status.micro_injection_aborted, @mi_attempt.status
      end

      should 'transition back from Chimeras obtained to Micro-injection in progress is total_male_chimeras is set back to 0' do
        @mi_attempt.total_male_chimeras = 1
        @mi_attempt.save!
        assert_equal MiAttempt::Status.chimeras_obtained, @mi_attempt.status

        @mi_attempt.total_male_chimeras = 0
        @mi_attempt.save!
        assert_equal MiAttempt::Status.micro_injection_in_progress, @mi_attempt.status
      end

      should 'ignore is_released_from_genotyping flag' do
        @mi_attempt.number_of_chimeras_with_glt_from_genotyping = 0
        @mi_attempt.number_of_het_offspring = nil
        @mi_attempt.total_male_chimeras = 1
        @mi_attempt.is_released_from_genotyping = true
        @mi_attempt.save!
        assert_equal MiAttempt::Status.chimeras_obtained, @mi_attempt.status
      end

      should 'not add the same status twice' do
        @mi_attempt.total_male_chimeras = 1
        @mi_attempt.save!
        @mi_attempt.save!
        assert_equal 2, @mi_attempt.status_stamps.size
      end
    end

    context 'is_active flag' do
      context 'when set to false' do
        context 'when production centre is WTSI' do
          should 'set status to aborted, even if is_released_from_gentotyping is true' do
            mi = Factory.create :mi_attempt2,
                    :mi_plan => bash_wtsi_cbx1_plan,
                    :is_released_from_genotyping => true,
                    :is_active => false

            assert_equal MiAttempt::Status.micro_injection_aborted, mi.status
          end
        end

        context 'when production centre is not WTSI' do
          should 'set status to aborted, even if genotype confirmed conditions are met' do
            mi = Factory.create :mi_attempt2,
                    :mi_plan => TestDummy.mi_plan('BaSH', 'ICS'),
                    :number_of_het_offspring => 1,
                    :is_active => false

            assert_equal MiAttempt::Status.micro_injection_aborted, mi.status
          end
        end
      end

      context 'when was false (and status was aborted) and is set to true' do
        should 'add an in-progress status' do
          mi = Factory.create :mi_attempt2,
                  :mi_plan => TestDummy.mi_plan('BaSH', 'ICS'),
                  :is_active => false

          mi.is_active = true
          mi.save!

          assert_equal MiAttempt::Status.micro_injection_in_progress, mi.status
        end

        should 're-evaluate status based on rules and set to confirmed' do
          mi = Factory.create :mi_attempt2_status_gtc,
                  :is_active => false
          assert_equal MiAttempt::Status.micro_injection_aborted, mi.status

          mi.is_active = true
          mi.save!

          assert_equal MiAttempt::Status.genotype_confirmed, mi.status
        end
      end
    end

    should 'avoid adding the same status twice consecutively' do
      mi = Factory.create :mi_attempt2,
              :mi_plan => TestDummy.mi_plan('BaSH', 'ICS')
      mi.save!
      mi.update_attributes!(:total_male_chimeras => 1)
      mi.save!
      mi.update_attributes!(:number_of_het_offspring => 1)
      mi.save!
      mi.update_attributes!(:is_active => false)
      mi.save!

      expected_statuses = [
        MiAttempt::Status.micro_injection_in_progress,
        MiAttempt::Status.chimeras_obtained,
        MiAttempt::Status.genotype_confirmed,
        MiAttempt::Status.micro_injection_aborted
      ].map(&:name)

      assert_equal expected_statuses, mi.status_stamps.map(&:name)
    end

    context 'status stamps' do
      should 'be created if conditions for a status are met' do
        mi = Factory.create :mi_attempt2
        assert_equal 1, mi.status_stamps.count

        set_mi_attempt_genotype_confirmed(mi)
        assert_equal 3, mi.status_stamps.count
        assert_equal 'gtc', mi.status_stamps.last.status.code
      end

      should 'be deleted if conditions for a status are not met' do
        mi = Factory.create :mi_attempt2, :is_active => false
        assert_equal 'abt', mi.status_stamps.last.status.code
        mi.update_attributes!(:is_active => true)
        assert_equal 'mip', mi.status_stamps.last.status.code
        assert_equal 1, mi.status_stamps.count
      end

      should_eventually 'have return order defined by StatusManager' do
        mi = Factory.create :mi_attempt2_status_gtc
        replace_status_stamps(mi,
          :gtc => '2011-01-01',
          :mip => '2011-01-02',
          :chr => '2011-01-03'
        )
        mi.reload
        assert_equal ['mip', 'chr', 'gtc'], mi.status_stamps.all.map(&:code)
      end
    end

  end
end
