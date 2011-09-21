# encoding: utf-8l

require 'test_helper'

class MiPlanTest < ActiveSupport::TestCase
  context 'MiPlan' do

    setup do
      @default_mi_plan = Factory.create :mi_plan
    end

    context '(misc. tests):' do
      should belong_to :gene
      should belong_to :consortium
      should belong_to :production_centre
      should belong_to :mi_plan_status
      should belong_to :mi_plan_priority

      should have_db_column(:gene_id).with_options(:null => false)
      should have_db_column(:consortium_id).with_options(:null => false)
      should have_db_column(:production_centre_id)
      should have_db_column(:mi_plan_status_id).with_options(:null => false)
      should have_db_column(:mi_plan_priority_id).with_options(:null => false)

      should have_many :mi_attempts

      should validate_presence_of :gene
      should validate_presence_of :consortium
      should validate_presence_of :mi_plan_status
      should validate_presence_of :mi_plan_priority

      context '#status_stamps' do
        should 'be a valid association'

        should 'be initialized to "interest"'
      end

      context '#add_status_stamp' do
        setup do
          @mi_plan_status_1 = MiPlanStatus.find_by_name!('Declined')
          @mi_plan_status_2 = MiPlanStatus.find_by_name!('Conflict')
          @default_mi_plan.status_stamps.destroy_all
          @default_mi_plan.add_status_stamp(@mi_plan_status_1)
          @default_mi_plan.add_status_stamp(@mi_plan_status_2)
        end

        should 'add the stamp' do
          assert_not_nil MiPlan::StatusStamp.where(
            :mi_plan_id => @default_mi_plan.id,
            :mi_plan_status_id => @mi_plan_status_1.id)
          assert_not_nil MiPlan::StatusStamp.where(
            :mi_plan_id => @default_mi_plan.id,
            :mi_plan_status_id => @mi_plan_status_2.id)
        end

        should 'update the association afterwards' do
          assert_equal [@mi_plan_status_1, @mi_plan_status_2],
                  default_mi_attempt.status_stamps.map(&:mi_plan_status)
        end
      end

      should 'validate the uniqueness of gene_id scoped to consortium_id and production_centre_id' do
        mip = Factory.build :mi_plan
        assert mip.save
        assert mip.valid?

        mip2 = MiPlan.new( :gene => mip.gene, :consortium => mip.consortium )
        assert_false mip2.save
        assert_false mip2.valid?
        assert ! mip2.errors['gene_id'].blank?

        mip.production_centre = Centre.find_by_name!('WTSI')
        assert mip.save
        assert mip.valid?

        mip2.production_centre = mip.production_centre
        assert_false mip2.save
        assert_false mip2.valid?
        assert ! mip2.errors['gene_id'].blank?

        # TODO: Need to account for the inevitable... we're gonna get MiP's that have
        #       a gene and consortium then nil for production_centre, and a duplicate
        #       with the same gene and consortium BUT with a production_centre assigned.
        #       Really, the fist should be updated to become the second (i.e. not produce a duplicate).
      end
    end

    context '::assign_genes_and_mark_conflicts' do
      setup do
        2.times { Factory.create :mi_attempt }
      end

      def setup_for_set_one_to_assigned
        gene = Factory.create :gene_cbx1
        @only_interest_mi_plan = Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!('BaSH')
        @declined_mi_plans = [
          Factory.create(:mi_plan, :gene => gene,
            :consortium => Consortium.find_by_name!('MGP'),
            :mi_plan_status => MiPlanStatus.find_by_name!('Declined - Conflict')),
          Factory.create(:mi_plan, :gene => gene,
            :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'),
            :mi_plan_status => MiPlanStatus.find_by_name!('Declined - Conflict'))
        ]

        MiPlan.assign_genes_and_mark_conflicts
        @only_interest_mi_plan.reload
        @declined_mi_plans.each(&:reload)
      end

      should 'set Interested MiPlan to Assigned status if no other Interested or Assigned MiPlan for the same gene exists' do
        setup_for_set_one_to_assigned
        assert_equal 'Assigned', @only_interest_mi_plan.mi_plan_status.name
        MiPlan.assign_genes_and_mark_conflicts
      end

      should 'not affect non-Interested MiPlans when setting Interested ones to Assigned' do
        setup_for_set_one_to_assigned
        assert_equal ['Declined - Conflict', 'Declined - Conflict'], @declined_mi_plans.map{|i| i.mi_plan_status.name}
        MiPlan.assign_genes_and_mark_conflicts
      end

      should 'set all Interested MiPlans that have the same gene to Conflict' do
        gene = Factory.create :gene_cbx1
        mi_plans = ['BaSH', 'MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!(consortium_name)
        end

        MiPlan.assign_genes_and_mark_conflicts

        mi_plans.each(&:reload)
        assert_equal ['Conflict', 'Conflict', 'Conflict'], mi_plans.map {|i| i.mi_plan_status.name }

        MiPlan.assign_genes_and_mark_conflicts
      end

      should 'set all Interested MiPlans to Conflict if other MiPlans for the same gene are in Conflict' do
        gene = Factory.create :gene_cbx1
        mi_plans = ['MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene,
                  :consortium => Consortium.find_by_name!(consortium_name),
                  :mi_plan_status => MiPlanStatus.find_by_name!('Conflict')
        end

        interested_mi_plan = Factory.create :mi_plan,
                :gene => gene, :consortium => Consortium.find_by_name!('BaSH')

        MiPlan.assign_genes_and_mark_conflicts
        interested_mi_plan.reload

        assert_equal 'Conflict', interested_mi_plan.mi_plan_status.name

        MiPlan.assign_genes_and_mark_conflicts
      end

      should 'set all interested MiPlans to "Declined - Conflict" if other MiPlans for the same gene are already Assigned' do
        gene = Factory.create :gene_cbx1
        Factory.create :mi_plan, :gene => gene,
                :consortium => Consortium.find_by_name!('BaSH'),
                :mi_plan_status => MiPlanStatus.find_by_name!('Assigned')

        mi_plans = ['MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!(consortium_name)
        end

        MiPlan.assign_genes_and_mark_conflicts
        mi_plans.each(&:reload)

        assert_equal ['Declined - Conflict', 'Declined - Conflict'], mi_plans.map {|i| i.mi_plan_status.name }
      end

      should 'set all interested MiPlans to "Declined - MI Attempt" if MiPlans with active MiAttempts already exist' do
        gene = Factory.create :gene_cbx1
        mi_plan = Factory.create :mi_plan,
                :gene              => gene,
                :consortium        => Consortium.find_by_name!('BaSH'),
                :mi_plan_status    => MiPlanStatus.find_by_name!('Assigned'),
                :production_centre => Centre.find_by_name!('BCM')

        mi_attempt = Factory.create(:mi_attempt, :es_cell => Factory.create(:es_cell, :gene => gene),
          :consortium_name => 'BaSH', :production_centre_name => 'BCM')

        assert_equal mi_plan, mi_attempt.mi_plan

        mi_plans = ['MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!(consortium_name)
        end

        MiPlan.assign_genes_and_mark_conflicts
        mi_plans.each(&:reload)

        assert_equal ['Declined - MI Attempt', 'Declined - MI Attempt'], mi_plans.map {|i| i.mi_plan_status.name }
      end

      should 'set all interested MiPlans to "Declined - GLT Mouse" if MiPlans with GLT Mice already exist' do
        gene = Factory.create :gene_cbx1
        mi_plan = Factory.create :mi_plan,
          :gene              => gene,
          :consortium        => Consortium.find_by_name!('BaSH'),
          :mi_plan_status    => MiPlanStatus.find_by_name!('Assigned'),
          :production_centre => Centre.find_by_name!('BCM')

        mi_attempt = Factory.create :mi_attempt,
          :es_cell                  => Factory.create(:es_cell, :gene => gene),
          :consortium_name          => 'BaSH',
          :production_centre_name   => 'BCM',
          :number_of_het_offspring  => 12

        assert_equal mi_plan, mi_attempt.mi_plan
        assert_equal MiAttemptStatus.genotype_confirmed.description, mi_attempt.status

        mi_plans = ['MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!(consortium_name)
        end

        mi_plans.each { |plan| assert_equal MiPlanStatus.find_by_name!('Interest'), plan.mi_plan_status }

        MiPlan.assign_genes_and_mark_conflicts
        mi_plans.each(&:reload)

        assert_equal ['Declined - GLT Mouse', 'Declined - GLT Mouse'], mi_plans.map {|i| i.mi_plan_status.name }
      end

    end # ::assign_genes_and_mark_conflicts

    context '::all_grouped_by_mgi_accession_id_then_by_status_name' do
      should 'work' do
        Factory.create :consortium, :name => 'Consortium X'
        gene1 = Factory.create :gene_cbx1
        gene2 = Factory.create :gene_trafd1
        bash = Factory.create :mi_plan, :gene => gene1,
                :consortium => Consortium.find_by_name!('BaSH'),
                :mi_plan_status => MiPlanStatus.find_by_name!('Interest')
        consortium_x = Factory.create :mi_plan, :gene => gene1,
                :consortium => Consortium.find_by_name!('Consortium X'),
                :mi_plan_status => MiPlanStatus.find_by_name!('Interest')
        mgp = Factory.create :mi_plan, :gene => gene1,
                :consortium => Consortium.find_by_name!('MGP'),
                :mi_plan_status => MiPlanStatus.find_by_name!('Assigned')
        eucomm = Factory.create :mi_plan, :gene => gene2,
                :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'),
                :mi_plan_status => MiPlanStatus.find_by_name!('Declined - Conflict')

        result = MiPlan.all_grouped_by_mgi_accession_id_then_by_status_name

        assert_equal [bash, consortium_x].sort, result[gene1.mgi_accession_id]['Interest'].sort
        assert_equal [mgp], result[gene1.mgi_accession_id]['Assigned']
        assert_equal [eucomm], result[gene2.mgi_accession_id]['Declined - Conflict']
      end
    end

    context '::with_mi_attempt' do
      should 'work' do
        10.times { Factory.create :mi_plan }
        10.times { Factory.create :mi_attempt }

        assert MiPlan.count > MiPlan.with_mi_attempt.count
        assert_equal 21, MiPlan.count
        assert_equal 10, MiPlan.with_mi_attempt.count
      end
    end

    context '::with_active_mi_attempt' do
      should 'work' do
        10.times { Factory.create :mi_plan }
        10.times { Factory.create :mi_attempt, :is_active => true }
        10.times { Factory.create :mi_attempt, :is_active => false }

        assert MiPlan.count > MiPlan.with_active_mi_attempt.count
        assert_equal 31, MiPlan.count
        assert_equal 10, MiPlan.with_active_mi_attempt.count
      end
    end

    context '::without_mi_attempt' do
      should 'work' do
        10.times { Factory.create :mi_plan }
        10.times { Factory.create :mi_attempt }

        assert MiPlan.count > MiPlan.without_mi_attempt.count
        assert_equal 21, MiPlan.count
        assert_equal 11, MiPlan.without_mi_attempt.count
      end
    end

    context '::without_active_mi_attempt' do
      should 'work' do
        10.times { Factory.create :mi_plan }
        10.times { Factory.create :mi_attempt, :is_active => true }
        10.times { Factory.create :mi_attempt, :is_active => false }

        assert MiPlan.count > MiPlan.without_active_mi_attempt.count
        assert_equal 31, MiPlan.count
        assert_equal 21, MiPlan.without_active_mi_attempt.count
      end
    end

    context '::with_genotype_confirmed_mouse' do
      should 'work' do
        10.times { Factory.create :mi_plan }
        10.times { Factory.create :mi_attempt, :is_active => true }
        10.times do
          Factory.create :mi_attempt,
            :number_of_het_offspring => 12,
            :production_centre_name => 'ICS',
            :is_active => true
        end

        assert MiPlan.count > MiPlan.with_genotype_confirmed_mouse.count
        assert_equal 31, MiPlan.count
        assert_equal 10, MiPlan.with_genotype_confirmed_mouse.count
      end
    end

  end
end
