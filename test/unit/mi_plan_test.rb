# encoding: utf-8

require 'test_helper'

class MiPlanTest < ActiveSupport::TestCase
  context 'MiPlan' do

    setup do
      @default_mi_plan = Factory.create :mi_plan
    end

    should 'have default sub_project on new mi_plan' do
      mi_plan = Factory.create :mi_plan
      assert_equal '', mi_plan.sub_project.name
    end

    should '@default_mi_plan should be in state Interest for the rest of the tests' do
      assert_equal 'Interest', @default_mi_plan.mi_plan_status.name
    end

    context 'attribute tests:' do
      should have_db_column(:sub_project_id).with_options(:null => false)    
      should belong_to :sub_project
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

        should 'delete related MiPlanStatusStamps as well' do
          plan = Factory.create :mi_plan_with_production_centre
          plan.mi_plan_status = MiPlanStatus['Conflict']; plan.save!
          plan.number_of_es_cells_starting_qc = 5; plan.save!
          stamps = plan.status_stamps.dup
          assert_equal 3, stamps.size

          plan.destroy

          stamps = stamps.map {|s| MiPlan::StatusStamp.find_by_id s.id}
          assert_equal [nil, nil, nil], stamps
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
          @default_mi_plan.status = 'Conflict'; @default_mi_plan.save!
          @default_mi_plan.status = 'Assigned'; @default_mi_plan.save!
          @default_mi_plan.status = 'Interest'; @default_mi_plan.save!

          expected = ['Interest', 'Conflict', 'Assigned', 'Interest']
          assert_equal expected, @default_mi_plan.status_stamps.map{|i| i.mi_plan_status.name}
        end

        should 'not add the same status stamp consecutively' do
          @default_mi_plan.status = 'Interest'; @default_mi_plan.save!
          @default_mi_plan.status = 'Interest'; @default_mi_plan.save!

          assert_equal ['Interest'], @default_mi_plan.status_stamps.map{|i|i.mi_plan_status.name}
        end
      end

      context '#status' do
        should 'use AccessAssociationByAttribute' do
          status = MiPlanStatus[:Conflict]
          assert_not_equal status, @default_mi_plan.mi_plan_status
          @default_mi_plan.status = 'Conflict'
          assert_equal status, @default_mi_plan.mi_plan_status
        end

        should 'be Interest by default' do
          plan = MiPlan.new
          plan.valid?
          assert_equal 'Interest', plan.status
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

      context '#number_of_es_cells_starting_qc' do
        should 'exist' do
          assert_should have_db_column(:number_of_es_cells_starting_qc).of_type(:integer)
        end

        should 'validate non-blankness only it was previously set to a number' do
          assert_equal nil, @default_mi_plan.number_of_es_cells_starting_qc
          @default_mi_plan.number_of_es_cells_starting_qc = 5
          @default_mi_plan.save!

          @default_mi_plan.number_of_es_cells_starting_qc = nil
          assert_false @default_mi_plan.save

          assert ! @default_mi_plan.errors[:number_of_es_cells_starting_qc].blank?
        end

        should 'be setsame value as number passing QC if it is null' do
          assert_nil @default_mi_plan.number_of_es_cells_starting_qc
          assert_nil @default_mi_plan.number_of_es_cells_passing_qc

          @default_mi_plan.number_of_es_cells_passing_qc = 7
          @default_mi_plan.valid?
          assert_equal 7, @default_mi_plan.number_of_es_cells_starting_qc

          @default_mi_plan.number_of_es_cells_passing_qc = 2
          @default_mi_plan.valid?
          assert_equal 7, @default_mi_plan.number_of_es_cells_starting_qc
        end
      end

      context '#number_of_es_cells_passing_qc' do
        should 'exist' do
          assert_should have_db_column(:number_of_es_cells_passing_qc).of_type(:integer)
        end

        should 'validate non-blankness only it was previously set to a number' do
          assert_equal nil, @default_mi_plan.number_of_es_cells_passing_qc
          @default_mi_plan.number_of_es_cells_passing_qc = 5
          @default_mi_plan.save!

          @default_mi_plan.number_of_es_cells_passing_qc = nil
          assert_false @default_mi_plan.save

          assert ! @default_mi_plan.errors[:number_of_es_cells_passing_qc].blank?
        end

        should 'validate cannot be set to 0 if was previously non-zero' do
          2.times do |i|
            @default_mi_plan.number_of_es_cells_passing_qc = 0
            @default_mi_plan.save!
          end

          @default_mi_plan.number_of_es_cells_passing_qc = 5
          @default_mi_plan.save!

          @default_mi_plan.number_of_es_cells_passing_qc = nil
          assert_false @default_mi_plan.save
          assert ! @default_mi_plan.errors[:number_of_es_cells_passing_qc].blank?

          @default_mi_plan.number_of_es_cells_passing_qc = 0
          assert_false @default_mi_plan.save
          assert ! @default_mi_plan.errors[:number_of_es_cells_passing_qc].blank?
        end
      end

      context '#withdrawn virtual attribute' do
        context 'when being set to true' do
          should 'set the status to Withdrawn if it at an allowed status' do
            @default_mi_plan.mi_plan_status = MiPlanStatus['Conflict']
            @default_mi_plan.withdrawn = true
            assert_equal true, @default_mi_plan.withdrawn
            assert_equal 'Withdrawn', @default_mi_plan.status

            @default_mi_plan.mi_plan_status = MiPlanStatus['Inspect - Conflict']
            @default_mi_plan.withdrawn = true
            assert_equal true, @default_mi_plan.withdrawn
            assert_equal 'Withdrawn', @default_mi_plan.status
          end

          should 'raise an error if not at an allowed status' do
            @default_mi_plan.mi_plan_status = MiPlanStatus['Assigned']
            assert_raise RuntimeError, 'cannot withdraw from status Assigned' do
              @default_mi_plan.withdrawn = true
            end
            assert_equal false, @default_mi_plan.withdrawn
            assert_equal 'Assigned', @default_mi_plan.status
          end
        end

        context 'when being set to false' do
          should 'not allow it if withdrawn' do
            @default_mi_plan.mi_plan_status = MiPlanStatus['Conflict']
            @default_mi_plan.withdrawn = true
            assert_raise RuntimeError, 'withdrawal cannot be reversed' do
              @default_mi_plan.withdrawn = false
            end
          end

          should 'allow it if not already withdrawn' do
            assert_nothing_raised do
              @default_mi_plan.withdrawn = false
            end
          end
        end

        should 'return true if status is Withdrawn' do
          @default_mi_plan.mi_plan_status = MiPlanStatus['Withdrawn']
          assert_equal true, @default_mi_plan.withdrawn
        end

        should 'return false if status is not Withdrawn' do
          @default_mi_plan.mi_plan_status = MiPlanStatus['Assigned']
          assert_equal false, @default_mi_plan.withdrawn
          @default_mi_plan.mi_plan_status = MiPlanStatus['Conflict']
          assert_equal false, @default_mi_plan.withdrawn
        end

        should 'be readable as #withdrawn?' do
          assert_false @default_mi_plan.withdrawn?
          @default_mi_plan.mi_plan_status = MiPlanStatus['Conflict']
          @default_mi_plan.withdrawn = true
          assert_true @default_mi_plan.withdrawn?
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
          'priority',
          'number_of_es_cells_starting_qc',
          'number_of_es_cells_passing_qc',
          'withdrawn'
        ]
        got = (MiPlan.accessible_attributes.to_a - ['audit_comment'])
        assert_equal expected.sort, got.sort
      end

      should 'have defined attributes in JSON output' do
        expected = [
          'id',
          'marker_symbol',
          'consortium_name',
          'production_centre_name',
          'priority',
          'status',
          'number_of_es_cells_starting_qc',
          'number_of_es_cells_passing_qc',
          'withdrawn'
        ]
        got = @default_mi_plan.as_json.keys
        assert_equal expected.sort, got.sort
      end
    end

    context '::major_conflict_resolution' do
      setup do
        2.times { Factory.create :mi_attempt }
      end

      def setup_for_set_one_to_assigned
        gene = Factory.create :gene_cbx1
        @only_interest_mi_plan = Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!('BaSH')
        @inspect_mi_plans = [
          Factory.create(:mi_plan, :gene => gene,
            :consortium => Consortium.find_by_name!('MGP'),
            :mi_plan_status => MiPlanStatus.find_by_name!('Inspect - Conflict')),
          Factory.create(:mi_plan, :gene => gene,
            :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'),
            :mi_plan_status => MiPlanStatus.find_by_name!('Inspect - Conflict'))
        ]

        MiPlan.major_conflict_resolution
        @only_interest_mi_plan.reload
        @inspect_mi_plans.each(&:reload)
      end

      should 'set Interested MiPlan to Assigned status if no other Interested or Assigned MiPlan for the same gene exists' do
        setup_for_set_one_to_assigned
        assert_equal 'Assigned', @only_interest_mi_plan.mi_plan_status.name
        MiPlan.major_conflict_resolution
      end

      should 'not affect non-Interested MiPlans when setting Interested ones to Assigned' do
        setup_for_set_one_to_assigned
        assert_equal ['Inspect - Conflict', 'Inspect - Conflict'], @inspect_mi_plans.map{|i| i.mi_plan_status.name}
        MiPlan.major_conflict_resolution
      end

      should 'set all Interested MiPlans that have the same gene to Conflict' do
        gene = Factory.create :gene_cbx1
        mi_plans = ['BaSH', 'MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!(consortium_name)
        end

        MiPlan.major_conflict_resolution

        mi_plans.each(&:reload)
        assert_equal ['Conflict', 'Conflict', 'Conflict'], mi_plans.map {|i| i.mi_plan_status.name }

        MiPlan.major_conflict_resolution
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

        MiPlan.major_conflict_resolution
        interested_mi_plan.reload

        assert_equal 'Conflict', interested_mi_plan.mi_plan_status.name

        MiPlan.major_conflict_resolution
      end

      should 'set all interested MiPlans to "Inspect - Conflict" if other MiPlans for the same gene are already Assigned' do
        gene = Factory.create :gene_cbx1
        Factory.create :mi_plan, :gene => gene,
                :consortium => Consortium.find_by_name!('BaSH'),
                :mi_plan_status => MiPlanStatus.find_by_name!('Assigned')

        mi_plans = ['MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!(consortium_name)
        end

        MiPlan.major_conflict_resolution
        mi_plans.each(&:reload)

        assert_equal ['Inspect - Conflict', 'Inspect - Conflict'], mi_plans.map {|i| i.mi_plan_status.name }
      end

      should 'set all interested MiPlans to "Inspect - Conflict" if other MiPlans for the same gene are already in an alternative Assigned state (like the ES Cell QC ones)' do
        gene = Factory.create :gene_cbx1
        plan = Factory.create :mi_plan, :gene => gene,
                :consortium => Consortium.find_by_name!('BaSH'),
                :number_of_es_cells_starting_qc => 5
        assert_equal 'Assigned - ES Cell QC In Progress', plan.status

        mi_plans = ['MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!(consortium_name)
        end

        MiPlan.major_conflict_resolution
        mi_plans.each(&:reload)

        assert_equal ['Inspect - Conflict', 'Inspect - Conflict'], mi_plans.map {|i| i.mi_plan_status.name }
      end

      should 'set all interested MiPlans to "Inspect - MI Attempt" if MiPlans with active MiAttempts already exist' do
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

        MiPlan.major_conflict_resolution
        mi_plans.each(&:reload)

        assert_equal ['Inspect - MI Attempt', 'Inspect - MI Attempt'], mi_plans.map {|i| i.mi_plan_status.name }
      end

      should 'set all interested MiPlans to "Inspect - GLT Mouse" if MiPlans with GLT Mice already exist' do
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

        MiPlan.major_conflict_resolution
        mi_plans.each(&:reload)

        assert_equal ['Inspect - GLT Mouse', 'Inspect - GLT Mouse'], mi_plans.map {|i| i.mi_plan_status.name }
      end

      should 'ignore "Inactive" MiPlans when making decisions' do
        gene    = Factory.create :gene_cbx1
        mi_plan = Factory.create :mi_plan,
                :gene => gene,
                :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC')
        inactive_mi_plan = Factory.create :mi_plan,
                :gene => gene,
                :consortium => Consortium.find_by_name!('JAX'),
                :production_centre => Centre.find_by_name!('JAX'),
                :mi_plan_status => MiPlanStatus['Inactive']

        assert_equal 'Interest', mi_plan.status
        assert_equal 'Inactive', inactive_mi_plan.status

        MiPlan.major_conflict_resolution

        assert_equal 'Assigned', mi_plan.reload.status
        assert_equal 'Inactive', inactive_mi_plan.reload.status
      end

    end # ::major_conflict_resolution

    context '::minor_conflict_resolution' do
      should 'not change status of any assigned MiPlans' do
        plan = Factory.create :mi_plan_with_production_centre,
                :number_of_es_cells_starting_qc => 4
        assert plan.assigned?
        MiPlan.minor_conflict_resolution
        plan.reload
        assert_equal 'Assigned - ES Cell QC In Progress', plan.status
      end

      [
        'Conflict',
        'Inspect - Conflict',
        'Inspect - MI Attempt',
        'Inspect - GLT Mouse'
      ].each do |status_name|
        should "Assign an MiPlan in status #{status_name} if it is the only one for a gene" do
          plan = Factory.create :mi_plan_with_production_centre,
                  :mi_plan_status => MiPlanStatus[status_name]
          MiPlan.minor_conflict_resolution
          plan.reload
          assert_equal 'Assigned', plan.status
        end

        should "not Assign MiPlan in status #{status_name} if an Assigned one exists for that gene" do
          gene = Factory.create :gene_cbx1
          Factory.create :mi_plan_with_production_centre,
                  :number_of_es_cells_passing_qc => 2,
                  :gene => gene
          plan = Factory.create :mi_plan_with_production_centre,
                  :mi_plan_status => MiPlanStatus[status_name],
                  :gene => gene
          MiPlan.minor_conflict_resolution
          plan.reload
          assert_equal status_name, plan.status
        end
      end

      [
        'Interest',
        'Withdrawn',
        'Aborted - ES Cell QC Failed'
      ].each do |status_name|
        should "not change the status of MiPlan with status #{status_name} even if it is the only one for a gene" do
          plan = Factory.create :mi_plan_with_production_centre,
                  :mi_plan_status => MiPlanStatus[status_name]
          MiPlan.minor_conflict_resolution
          plan.reload
          assert_equal status_name, plan.status
        end
      end

      should 'not change status of Inspect or Conflict MiPlans if there are more than one of them for a gene' do
        gene = Factory.create :gene_cbx1
        plan1 = Factory.create :mi_plan_with_production_centre,
                :mi_plan_status => MiPlanStatus['Conflict'],
                :gene => gene
        plan2 = Factory.create :mi_plan_with_production_centre,
                :mi_plan_status => MiPlanStatus['Inspect - MI Attempt'],
                :gene => gene
        MiPlan.minor_conflict_resolution
        plan1.reload; plan2.reload
        assert_equal 'Conflict', plan1.status
        assert_equal 'Inspect - MI Attempt', plan2.status
      end

      should 'change the status of a Conflct MiPlan if it is the only one for a gene' do
        gene = Factory.create :gene_cbx1
        conflict_plan = Factory.create :mi_plan_with_production_centre,
                :mi_plan_status => MiPlanStatus['Conflict'],
                :gene => gene

        MiPlan.minor_conflict_resolution

        conflict_plan.reload
        assert_equal 'Assigned', conflict_plan.status
      end
    end # ::minor_conflict_resolution

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
                :mi_plan_status => MiPlanStatus.find_by_name!('Inspect - Conflict')

        result = MiPlan.all_grouped_by_mgi_accession_id_then_by_status_name

        gene1_interest_results = result[gene1.mgi_accession_id]['Interest']
        assert_include gene1_interest_results, bash
        assert_include gene1_interest_results, consortium_x
        assert_equal 2, gene1_interest_results.size

        assert_equal [mgp], result[gene1.mgi_accession_id]['Assigned']
        assert_equal [eucomm], result[gene2.mgi_accession_id]['Inspect - Conflict']
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
                :mi_date => 9.months.ago

        old_failed_mi_attempt_2 = Factory.create :mi_attempt,
                :es_cell => es_cell,
                :consortium_name => 'DTCC',
                :production_centre_name => 'WTSI',
                :is_active => false,
                :mi_date => 9.months.ago
        old_failed_mi_attempt_2.mi_plan.number_of_es_cells_starting_qc = 5
        old_failed_mi_attempt_2.mi_plan.save!

        mi_plan_no_attempts = Factory.create :mi_plan,
                :gene => cbx1,
                :consortium => Consortium.find_by_name!('JAX'),
                :production_centre => Centre.find_by_name!('JAX'),
                :mi_plan_status => MiPlanStatus.find_by_name!('Assigned')

        es_qc_mi_plan_no_attempts = Factory.create :mi_plan,
                :gene => cbx1,
                :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'),
                :production_centre => Centre.find_by_name!('JAX'),
                :number_of_es_cells_starting_qc => 6

        assert_equal 'Assigned', gc_mi_attempt.mi_plan.status
        assert_equal 'Assigned', in_prog_mi_attempt.mi_plan.status
        assert_equal 'Assigned', old_failed_mi_attempt.mi_plan.status
        assert_equal 'Assigned - ES Cell QC In Progress', old_failed_mi_attempt_2.mi_plan.status
        assert_equal 'Assigned', mi_plan_no_attempts.status
        assert_equal 'Assigned - ES Cell QC In Progress', es_qc_mi_plan_no_attempts.status

        MiPlan.mark_old_plans_as_inactive

        assert_equal 'Assigned', gc_mi_attempt.reload.mi_plan.status
        assert_equal 'Assigned', in_prog_mi_attempt.reload.mi_plan.status
        assert_equal 'Inactive', old_failed_mi_attempt.reload.mi_plan.status
        assert_equal 'Inactive', old_failed_mi_attempt_2.reload.mi_plan.status
        assert_equal 'Assigned', mi_plan_no_attempts.reload.status
        assert_equal 'Assigned - ES Cell QC In Progress', es_qc_mi_plan_no_attempts.status

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

    context '::check_for_upgradeable' do
      should 'return the one with the same marker symbol and consortium but no production centre' do
        gene = Factory.create :gene_cbx1
        consortium = Consortium.find_by_name!('BaSH')
        plan = Factory.create :mi_plan, :gene => gene, :consortium => consortium,
                :production_centre => nil

        got = MiPlan.check_for_upgradeable(:marker_symbol => gene.marker_symbol,
          :consortium_name => consortium.name, :production_centre_name => 'WTSI')
        assert_equal plan, got
      end

      should 'return nil if no match' do
        cbx1 = Factory.create :gene_cbx1
        bash = Consortium.find_by_name!('BaSH')
        wtsi = Centre.find_by_name!('WTSI')
        Factory.create :mi_plan, :gene => cbx1, :consortium => bash,
                :production_centre => wtsi

        got = MiPlan.check_for_upgradeable(:marker_symbol => cbx1.marker_symbol,
          :consortium_name => bash.name, :production_centre_name => 'ICS')
        assert_nil got
      end
    end

    context '#assigned?' do
      should 'return true if status is assigned' do
        plan = Factory.build :mi_plan_with_production_centre
        plan.mi_plan_status = MiPlanStatus['Assigned']
        assert plan.assigned?

        plan.mi_plan_status = MiPlanStatus['Assigned - ES Cell QC In Progress']
        assert plan.assigned?

        plan.mi_plan_status = MiPlanStatus['Assigned - ES Cell QC Complete']
        assert plan.assigned?
      end

      should 'return false if status is not assigned' do
        plan = Factory.build :mi_plan_with_production_centre
        plan.mi_plan_status = MiPlanStatus['Inactive']
        assert_false plan.assigned?

        plan.mi_plan_status = MiPlanStatus['Conflict']
        assert_false plan.assigned?
      end
    end

    context '#reason_for_inspect_or_conflict' do
      setup do
        @gene = Factory.create :gene_cbx1
        @eucomm_cons = Consortium.find_by_name!('EUCOMM-EUMODIC')
        @bash_cons = Consortium.find_by_name!('BaSH')
        @mgp_cons = Consortium.find_by_name!('MGP')
        @ics_cent = Centre.find_by_name!('ICS')
        @jax_cent = Centre.find_by_name!('JAX')
        @cnb_cent = Centre.find_by_name!('CNB')
      end

      should 'correctly return for Inspect - GLT Mouse' do
        mi_attempt = Factory.create :mi_attempt,
                :es_cell => Factory.create(:es_cell, :gene => @gene),
                :consortium_name => @eucomm_cons.name,
                :production_centre_name => @ics_cent.name
        set_mi_attempt_genotype_confirmed(mi_attempt)

        mi_attempt = Factory.create :mi_attempt,
                :es_cell => Factory.create(:es_cell, :gene => @gene),
                :consortium_name => @bash_cons.name,
                :production_centre_name => @jax_cent.name
        set_mi_attempt_genotype_confirmed(mi_attempt)

        mi_plan = Factory.create :mi_plan, :gene => @gene,
                :consortium => @mgp_cons, :production_centre => @cnb_cent

        MiPlan.major_conflict_resolution
        mi_plan.reload; assert_equal 'Inspect - GLT Mouse', mi_plan.status

        assert_equal "GLT mouse produced at: #{@ics_cent.name} (#{@eucomm_cons.name}), #{@jax_cent.name} (#{@bash_cons.name})",
                mi_plan.reason_for_inspect_or_conflict
      end

      should 'correctly return for Inspect - MI Attempt' do
        mi_attempt = Factory.create :mi_attempt,
                :es_cell => Factory.create(:es_cell, :gene => @gene),
                :consortium_name => @eucomm_cons.name,
                :production_centre_name => @ics_cent.name

        mi_attempt = Factory.create :mi_attempt,
                :es_cell => Factory.create(:es_cell, :gene => @gene),
                :consortium_name => @bash_cons.name,
                :production_centre_name => @jax_cent.name,
                :is_active => true

        mi_plan = Factory.create :mi_plan, :gene => @gene,
                :consortium => @mgp_cons, :production_centre => @cnb_cent

        MiPlan.major_conflict_resolution
        mi_plan.reload; assert_equal 'Inspect - MI Attempt', mi_plan.status

        assert_equal "MI already in progress at: #{@ics_cent.name} (#{@eucomm_cons.name}), #{@jax_cent.name} (#{@bash_cons.name})",
                mi_plan.reason_for_inspect_or_conflict
      end

      should 'correctly return for Inspect - Conflict' do
        Factory.create :mi_attempt

        Factory.create :mi_plan, :gene => @gene,
                :consortium => @eucomm_cons, :production_centre => @ics_cent,
                :mi_plan_status => MiPlanStatus[:Assigned]

        Factory.create :mi_plan, :gene => @gene,
                :consortium => @bash_cons, :production_centre => @jax_cent,
                :number_of_es_cells_starting_qc => 5

        mi_plan = Factory.create :mi_plan, :gene => @gene,
                :consortium => @mgp_cons, :production_centre => @cnb_cent

        MiPlan.major_conflict_resolution
        mi_plan.reload; assert_equal 'Inspect - Conflict', mi_plan.status

        assert_equal "Other 'Assigned' MI plans for: #{@eucomm_cons.name}, #{@bash_cons.name}",
                mi_plan.reason_for_inspect_or_conflict
      end

      should 'correctly return for Conflict' do
        Factory.create :mi_attempt

        Factory.create :mi_plan, :gene => @gene,
                :consortium => @eucomm_cons, :production_centre => @ics_cent

        Factory.create :mi_plan, :gene => @gene,
                :consortium => @bash_cons, :production_centre => @jax_cent

        mi_plan = Factory.create :mi_plan, :gene => @gene,
                :consortium => @mgp_cons, :production_centre => @cnb_cent

        MiPlan.major_conflict_resolution
        mi_plan.reload; assert_equal 'Conflict', mi_plan.status

        assert_equal "Other MI plans for: #{@eucomm_cons.name}, #{@bash_cons.name}",
                mi_plan.reason_for_inspect_or_conflict
      end

      should 'return nil if no conflict' do
        mi_plan = Factory.create :mi_plan
        assert_nil mi_plan.reason_for_inspect_or_conflict
      end
    end

    context '#as_json' do
      should 'take nil as param' do
        assert_nothing_raised { @default_mi_plan.as_json(nil) }
      end
    end

  end
end
