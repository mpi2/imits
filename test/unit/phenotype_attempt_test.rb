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
        new_mi = Factory.create :mi_attempt_genotype_confirmed,
                :es_cell => default_phenotype_attempt.mi_attempt.es_cell
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

    context '#mi_plan' do
      should 'be in DB' do
        assert_should have_db_column(:mi_plan_id).of_type(:integer).with_options(:null => false)
      end

      should 'work' do
        assert_should belong_to(:mi_plan)
      end

      should 'default to mi_attempt.mi_plan' do
        pt = Factory.create :phenotype_attempt, :mi_plan => nil
        assert_equal pt.mi_attempt.mi_plan, pt.mi_plan
      end

      should 'not be overritten by default value if it is explicitly set' do
        mi_attempt = Factory.create :mi_attempt_genotype_confirmed
        plan = Factory.create :mi_plan, :gene => mi_attempt.gene
        pt = Factory.create :phenotype_attempt, :mi_attempt => mi_attempt, :mi_plan => plan
        assert_equal plan, pt.mi_plan
        assert_not_equal pt.mi_attempt.mi_plan, pt.mi_plan
      end

      should 'validate as having same gene as mi_attempt.es_cell' do
        plan = Factory.create :mi_plan,
                :consortium => default_phenotype_attempt.mi_plan.consortium,
                :production_centre => default_phenotype_attempt.mi_plan.production_centre
        assert_not_equal plan.gene, default_phenotype_attempt.mi_attempt.es_cell.gene

        default_phenotype_attempt.mi_plan = plan
        assert ! default_phenotype_attempt.valid?
        assert_equal ['must have same gene as mi_attempt'], default_phenotype_attempt.errors[:mi_plan]
      end

      should 'get set to Assigned if not already in an assigned state' do
        plan = Factory.create :mi_plan, :gene => default_phenotype_attempt.gene,
                :status => MiPlan::Status['Assigned']
        default_phenotype_attempt.mi_plan = plan
        assert default_phenotype_attempt.save
        plan.reload; assert_equal 'Assigned', plan.status.name

        plan = Factory.create :mi_plan, :gene => default_phenotype_attempt.gene,
                :number_of_es_cells_starting_qc => 5
        default_phenotype_attempt.mi_plan = plan
        assert default_phenotype_attempt.save
        plan.reload; assert_equal 'Assigned - ES Cell QC In Progress', plan.status.name

        plan = Factory.create :mi_plan, :gene => default_phenotype_attempt.gene,
                :status => MiPlan::Status['Interest']
        default_phenotype_attempt.mi_plan = plan
        assert default_phenotype_attempt.save
        plan.reload; assert_equal 'Assigned', plan.status.name

        plan = Factory.create :mi_plan, :gene => default_phenotype_attempt.gene,
                :status => MiPlan::Status['Conflict']
        default_phenotype_attempt.mi_plan = plan
        assert default_phenotype_attempt.save
        plan.reload; assert_equal 'Assigned', plan.status.name
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

    context '#colony_name' do
      should 'exist and be not null' do
        assert_should have_db_column(:colony_name).with_options(:limit => 125, :null => false)
      end

      should 'have unique index' do
        assert_should have_db_index(:colony_name).unique(true)
      end

      should 'be auto-generated' do
        mi = Factory.create :mi_attempt_genotype_confirmed, :colony_name => 'ABCD123'

        pt = Factory.create :phenotype_attempt, :mi_attempt => mi
        assert_equal 'ABCD123-1', pt.colony_name

        pt = Factory.create :phenotype_attempt, :mi_attempt => mi
        assert_equal 'ABCD123-2', pt.colony_name
      end

      should 'not be overwritten by auto-generation if set' do
        pt = Factory.create :phenotype_attempt, :colony_name => 'XYZ789'
        assert_equal 'XYZ789', pt.colony_name
      end
    end

    context '#gene' do
      should 'be the mi_attempt\'s es_cell\'s gene' do
        assert_equal default_phenotype_attempt.mi_attempt.gene,
                default_phenotype_attempt.gene
      end
    end
    
    context '#inactive_phenotype_attempt' do
      should ', when reactivated, reactivate associated mi plan' do
        phenotype_attempt = Factory.create :phenotype_attempt, :is_active => false
        plan = phenotype_attempt.mi_plan
        plan.is_active = false
        plan.save!
        phenotype_attempt.is_active = true
        phenotype_attempt.save!
        assert phenotype_attempt.mi_plan.is_active?
      end
    end

  end
end
