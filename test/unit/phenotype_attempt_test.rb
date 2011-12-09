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

      should 'default to Registered' do
        pt = PhenotypeAttempt.new
        pt.valid?
        assert_equal PhenotypeAttempt::Status['Registered'], pt.status
      end

      should 'not overwrite a set status with default' do
        s = PhenotypeAttempt::Status.create!(:name => 'Nonexistent')
        pt = PhenotypeAttempt.new(:status => s)
        pt.valid?
        assert_equal s, pt.status
      end
    end

  end
end
