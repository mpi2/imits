# encoding: utf-8

require 'test_helper'

class PhenotypeAttemptTest < ActiveSupport::TestCase
  context 'PhenotypeAttempt' do

    def default_phenotype_attempt
      @default_phenotype_attempt ||= Factory.create :phenotype_attempt
    end

    should 'be audited' do
      default_phenotype_attempt.is_active = false
      default_phenotype_attempt.save!
      assert ! Audit.where(:auditable_type => 'PhenotypeAttempt',
        :auditable_id => default_phenotype_attempt.id).blank?
    end

    should 'have #is_active' do
      assert_should have_db_column(:is_active).with_options(:null => false, :default => true)
    end

    context '#mi_attempt' do
      should 'work' do
        assert_should belong_to :mi_attempt
      end

      should 'be assignable to Genotype confirmed MiAttempt' do
        new_mi = Factory.create :mi_attempt_genotype_confirmed
        default_phenotype_attempt.mi_attempt = new_mi
        default_phenotype_attempt.save!
      end

      should 'not be set to MiAttempt that is not Genotype confirmed' do
        new_mi = Factory.create :mi_attempt
        assert_equal MiAttemptStatus.micro_injection_in_progress, new_mi.mi_attempt_status
        default_phenotype_attempt.mi_attempt = new_mi
        default_phenotype_attempt.valid?
        assert_match /must be genotype confirmed/i, default_phenotype_attempt.errors['mi_attempt'].first
      end
    end

    context '#status' do
      should 'work' do
        assert_should belong_to :status
      end
    end

    context '#rederivation_started' do
      should 'be in DB' do
        assert_should have_db_column(:rederivation_started).with_options(:null => false, :default => false)
      end

      should 'default to false' do
        assert_equal false, default_phenotype_attempt.rederivation_started?
      end
    end

    context '#rederivation_complete' do
      should 'be in DB' do
        assert_should have_db_column(:rederivation_complete).with_options(:null => false, :default => false)
      end

      should 'default to false' do
        assert_equal false, default_phenotype_attempt.rederivation_complete?
      end
    end

    context '#number_of_cre_matings_started' do
      should 'be in DB' do
        assert_should have_db_column(:number_of_cre_matings_started).with_options(:null => false)
      end

      should 'default to false' do
        assert_equal 0, default_phenotype_attempt.number_of_cre_matings_started
      end
    end

    context '#number_of_cre_matings_successful' do
      should 'be in DB' do
        assert_should have_db_column(:number_of_cre_matings_successful).with_options(:null => false)
      end

      should 'default to false' do
        assert_equal 0, default_phenotype_attempt.number_of_cre_matings_successful
      end
    end

    context '#phenotyping_started' do
      should 'be in DB' do
        assert_should have_db_column(:phenotyping_started).with_options(:null => false, :default => false)
      end

      should 'default to false' do
        assert_equal false, default_phenotype_attempt.phenotyping_started?
      end
    end

    context '#phenotyping_complete' do
      should 'be in DB' do
        assert_should have_db_column(:phenotyping_complete).with_options(:null => false, :default => false)
      end

      should 'default to false' do
        assert_equal false, default_phenotype_attempt.phenotyping_complete?
      end
    end

    context '#status_stamps' do
      should 'be a valid association' do
        assert_should have_many :status_stamps
      end

      should 'be ordered by created_at asc' do
        default_phenotype_attempt.status_stamps.destroy_all
        status = PhenotypeAttempt::Status['Phenotype Attempt Registered']
        s1 = default_phenotype_attempt.status_stamps.create!(
          :status => status, :created_at => '2011-12-01 12:00:00 UTC')
        s2 = default_phenotype_attempt.status_stamps.create!(
          :status => status, :created_at => '2011-12-01 14:00:00 UTC')
        s3 = default_phenotype_attempt.status_stamps.create!(
          :status => status, :created_at => '2011-12-01 13:00:00 UTC')
        default_phenotype_attempt.reload
        assert_equal [s1, s3, s2].map(&:created_at), default_phenotype_attempt.status_stamps.map(&:created_at)
      end

      should 'be added when status changes' do
        assert_equal ['Phenotype Attempt Registered'], default_phenotype_attempt.status_stamps.map{|i| i.status.name}
        default_phenotype_attempt.rederivation_started = true
        default_phenotype_attempt.save!
        assert_equal ['Phenotype Attempt Registered', 'Rederivation Started'], default_phenotype_attempt.status_stamps.map{|i| i.status.name}
      end
    end

    context '#reportable_statuses_with_latest_dates' do
      should 'work' do
        default_phenotype_attempt.status_stamps.last.update_attributes!(
          :created_at => '2011-11-30 23:59:59 UTC')
        default_phenotype_attempt.status_stamps.create!(
          :status => PhenotypeAttempt::Status['Phenotype Attempt Registered'],
          :created_at => '2011-10-30 00:00:00 UTC')

        default_phenotype_attempt.number_of_cre_matings_started = 4
        default_phenotype_attempt.save!
        default_phenotype_attempt.status_stamps.last.update_attributes!(
          :created_at => '2011-12-01 23:59:59 UTC')

        default_phenotype_attempt.number_of_cre_matings_successful = 2
        default_phenotype_attempt.save!
        default_phenotype_attempt.status_stamps.last.update_attributes!(
          :created_at => '2011-12-02 23:59:59 UTC')

        default_phenotype_attempt.phenotyping_started = true
        default_phenotype_attempt.save!
        default_phenotype_attempt.status_stamps.last.update_attributes!(
          :created_at => '2011-12-03 23:59:59 UTC')

        expected = {
          'Phenotype Attempt Registered' => Date.parse('2011-11-30'),
          'Cre Excision Started' => Date.parse('2011-12-01'),
          'Cre Excision Complete' => Date.parse('2011-12-02'),
          'Phenotyping Started' => Date.parse('2011-12-03')
        }

        assert_equal expected, default_phenotype_attempt.reportable_statuses_with_latest_dates
      end
    end

  end
end
