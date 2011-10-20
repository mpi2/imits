# encoding: utf-8

require 'test_helper'

class MiPlanTest < ActiveSupport::TestCase
  context 'MiPlan' do

    setup do
      @default_mi_plan = Factory.create :mi_plan
    end

    should '@default_mi_plan should be in state Interest for the rest of the tests' do
      assert_equal 'Interest', @default_mi_plan.mi_plan_status.name
    end

    context 'attribute tests:' do
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

      context '#status_stamps' do
        should 'be a valid association' do
          assert_should have_many :status_stamps
        end

        should 'be "Interest" by default' do
          mi_plan = Factory.create :mi_plan
          assert_equal [MiPlanStatus[:Interest]], mi_plan.status_stamps.map(&:mi_plan_status)
        end

        should 'be ordered by created_at asc' do
          @default_mi_plan.status_stamps.destroy_all
          s1 = MiPlan::StatusStamp.create!(:mi_plan => @default_mi_plan,
            :mi_plan_status => MiPlanStatus[:Assigned], :created_at => 1.day.ago)
          s2 = MiPlan::StatusStamp.create!(:mi_plan => @default_mi_plan,
            :mi_plan_status => MiPlanStatus[:Conflict], :created_at => 1.hour.ago)
          s3 = MiPlan::StatusStamp.create!(:mi_plan => @default_mi_plan,
            :mi_plan_status => MiPlanStatus[:Interest], :created_at => 12.hours.ago)
          @default_mi_plan.status_stamps.reload
          assert_equal [s1, s3, s2].map(&:name), @default_mi_plan.status_stamps.map(&:name)
        end
      end

      context '#add_status_stamp' do
        setup do
          @default_mi_plan.status_stamps.destroy_all
          @default_mi_plan.send(:add_status_stamp, MiPlanStatus[:Assigned])
          @default_mi_plan.send(:add_status_stamp, MiPlanStatus[:Conflict])
        end

        should 'add the stamp' do
          assert_not_equal [], MiPlan::StatusStamp.where(
            :mi_plan_id => @default_mi_plan.id,
            :mi_plan_status_id => MiPlanStatus[:Assigned].id)
          assert_not_equal [], MiPlan::StatusStamp.where(
            :mi_plan_id => @default_mi_plan.id,
            :mi_plan_status_id => MiPlanStatus[:Conflict].id)
        end

        should 'update the association afterwards' do
          assert_equal [MiPlanStatus[:Assigned], MiPlanStatus[:Conflict]],
                  @default_mi_plan.status_stamps.map(&:mi_plan_status)
        end
      end

      context '#mi_plan_status=' do
        should 'create status stamps when status is changed' do
          @default_mi_plan.update_attributes!(:mi_plan_status => MiPlanStatus[:Conflict])
          @default_mi_plan.update_attributes!(:mi_plan_status => MiPlanStatus[:Assigned])
          @default_mi_plan.update_attributes!(:mi_plan_status => MiPlanStatus[:Interest])

          expected = [MiPlanStatus[:Interest], MiPlanStatus[:Conflict], MiPlanStatus[:Assigned], MiPlanStatus[:Interest]]
          assert_equal expected, @default_mi_plan.status_stamps.map(&:mi_plan_status)
        end

        should 'not add the same status stamp consecutively' do
          @default_mi_plan.update_attributes!(:mi_plan_status => MiPlanStatus[:Interest])
          @default_mi_plan.update_attributes!(:mi_plan_status => MiPlanStatus[:Interest])

          assert_equal [MiPlanStatus[:Interest]], @default_mi_plan.status_stamps.map(&:mi_plan_status)
        end
      end

      context '#marker_symbol' do
        should 'use AccessAssociationByAttribute' do
          gene = Factory.create :gene_cbx1
          @default_mi_plan.marker_symbol = 'Cbx1'
          assert_equal gene, @default_mi_plan.gene
        end

        should 'be present' do
          assert_should validate_presence_of :marker_symbol
        end
      end

      context '#consortium_name' do
        should 'use AccessAssociationByAttribute' do
          consortium = Factory.create :consortium
          @default_mi_plan.consortium_name = consortium.name
          assert_equal consortium, @default_mi_plan.consortium
        end

        should 'be present' do
          assert_should validate_presence_of :consortium_name
        end
      end

      context '#production_centre_name' do
        def centre
          @centre ||= Factory.create(:centre)
        end

        should 'use AccessAssociationByAttribute' do
          @default_mi_plan.production_centre_name = centre.name
          assert_equal centre, @default_mi_plan.production_centre
        end

        should 'not allow setting back to nil once assigned to something' do
          mi_plan = Factory.create :mi_plan, :production_centre_name => nil
          mi_plan.production_centre_name = centre.name
          assert mi_plan.save
          mi_plan.production_centre_name = nil
          assert ! mi_plan.valid?
          assert_include mi_plan.errors[:production_centre_name], 'cannot be blank'
        end

        should 'can say unset if it was initially so' do
          mip = Factory.build :mi_plan
          assert mip.save
          assert mip.valid?, mip.errors.inspect
        end
      end

      context '#status' do
        should 'be the most recent status name' do
          @default_mi_plan.mi_plan_status = MiPlanStatus[:Conflict]
          assert_equal 'Conflict', @default_mi_plan.status
        end
      end

      context '#priority' do
        should 'use AccessAssociationByAttribute' do
          priority = MiPlanPriority.find_by_name!('Medium')
          assert_not_equal priority,  @default_mi_plan.mi_plan_priority
          @default_mi_plan.priority = 'Medium'
          assert_equal priority, @default_mi_plan.mi_plan_priority
        end

        should 'be present' do
          assert_should validate_presence_of :priority
        end
      end

      should 'validate the uniqueness of gene_id scoped to consortium_id and production_centre_id' do
        mip = Factory.build :mi_plan
        assert mip.save
        assert mip.valid?, mip.errors.inspect

        mip2 = MiPlan.new(:marker_symbol => mip.gene.marker_symbol,
          :consortium_name => mip.consortium.name)
        assert_false mip2.save
        assert_false mip2.valid?
        assert ! mip2.errors['gene_id'].blank?

        mip.production_centre_name = 'WTSI'
        assert mip.save
        assert mip.valid?

        mip2.production_centre_name = mip.production_centre_name
        assert_false mip2.save
        assert_false mip2.valid?
        assert ! mip2.errors['gene_id'].blank?

        # TODO: Need to account for the inevitable... we're gonna get MiP's that have
        #       a gene and consortium then nil for production_centre, and a duplicate
        #       with the same gene and consortium BUT with a production_centre assigned.
        #       Really, the fist should be updated to become the second (i.e. not produce a duplicate).
      end

      should 'limit the public mass-assignment API' do
        expected = [
          'marker_symbol',
          'consortium_name',
          'production_centre_name',
          'priority'
        ]
        got = (MiPlan.accessible_attributes.to_a - ['audit_comment'])
        assert_equal expected, got
      end

      should 'have defined attributes in JSON output' do
        expected = [
          'id',
          'marker_symbol',
          'consortium_name',
          'production_centre_name',
          'priority'
        ]
        got = MiPlan.as_json.keys
        assert_equal expected, got
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

      should 'ignore "Inactive" MiPlans when making decisions' do
        gene              = Factory.create :gene_cbx1
        mi_plan           = Factory.create :mi_plan,
                :gene => gene,
                :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC')
        inactive_mi_plan  = Factory.create :mi_plan,
                :gene => gene,
                :consortium => Consortium.find_by_name!('JAX'),
                :production_centre => Centre.find_by_name!('JAX'),
                :mi_plan_status => MiPlanStatus['Inactive']

        assert_equal 'Interest', mi_plan.status
        assert_equal 'Inactive', inactive_mi_plan.status

        MiPlan.assign_genes_and_mark_conflicts

        assert_equal 'Assigned', mi_plan.reload.status
        assert_equal 'Inactive', inactive_mi_plan.reload.status
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

    context '::mark_old_plans_as_inactive' do
      should 'work' do
        cbx1 = Factory.create :gene_cbx1
        es_cell = Factory.create :es_cell, :gene => cbx1

        gc_mi_attempt = Factory.create :mi_attempt,
                :es_cell => es_cell,
                :consortium_name => 'BaSH',
                :production_centre_name => 'BCM',
                :is_active => true,
                :mi_date => 12.months.ago,
                :mi_attempt_status => MiAttemptStatus.genotype_confirmed

        in_prog_mi_attempt = Factory.create :mi_attempt,
                :es_cell => es_cell,
                :consortium_name => 'MARC',
                :production_centre_name => 'MARC',
                :is_active => true,
                :mi_date => 4.weeks.ago,
                :mi_attempt_status => MiAttemptStatus.micro_injection_in_progress

        Factory.create :mi_attempt,
                :es_cell => es_cell,
                :consortium_name => 'MARC',
                :production_centre_name => 'MARC',
                :is_active => false,
                :mi_date => 7.months.ago,
                :mi_attempt_status => MiAttemptStatus.micro_injection_aborted

        old_failed_mi_attempt = Factory.create :mi_attempt,
                :es_cell => es_cell,
                :consortium_name => 'DTCC',
                :production_centre_name => 'UCD',
                :is_active => false,
                :mi_date => 9.months.ago,
                :mi_attempt_status => MiAttemptStatus.micro_injection_aborted

        mi_plan_no_attempts = Factory.create :mi_plan,
                :gene => cbx1,
                :consortium => Consortium.find_by_name!('JAX'),
                :production_centre => Centre.find_by_name!('JAX'),
                :mi_plan_status => MiPlanStatus.find_by_name!('Assigned')

        assert_equal 'Assigned', gc_mi_attempt.mi_plan.status
        assert_equal 'Assigned', in_prog_mi_attempt.mi_plan.status
        assert_equal 'Assigned', old_failed_mi_attempt.mi_plan.status
        assert_equal 'Assigned', mi_plan_no_attempts.status

        MiPlan.mark_old_plans_as_inactive

        assert_equal 'Assigned', gc_mi_attempt.mi_plan.reload.status
        assert_equal 'Assigned', in_prog_mi_attempt.mi_plan.reload.status
        assert_equal 'Inactive', old_failed_mi_attempt.mi_plan.reload.status
        assert_equal 'Assigned', mi_plan_no_attempts.reload.status

        # Now test what happens if a centre re-visits an inactive MiPlan...
        new_mi_attempt = Factory.create :mi_attempt,
                :es_cell => es_cell,
                :consortium_name => 'DTCC',
                :production_centre_name => 'UCD',
                :is_active => true,
                :mi_date => 2.weeks.ago,
                :mi_attempt_status => MiAttemptStatus.micro_injection_in_progress

        assert_equal 'Assigned', old_failed_mi_attempt.mi_plan.reload.status
        assert_equal 'Assigned', new_mi_attempt.mi_plan.reload.status
      end
    end

  end
end
