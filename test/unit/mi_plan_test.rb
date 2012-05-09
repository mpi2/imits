# encoding: utf-8

require 'test_helper'

class MiPlanTest < ActiveSupport::TestCase

  context 'MiPlan' do

    def default_mi_plan
      @default_mi_plan ||= Factory.create :mi_plan
    end

    should 'default_mi_plan should be in state Interest for the rest of the tests' do
      assert_equal 'Interest', default_mi_plan.status.name
    end

    context 'attribute tests:' do
      should 'have associations' do
        assert_should belong_to :gene
        assert_should belong_to :consortium
        assert_should belong_to :production_centre
        assert_should belong_to :status
        assert_should belong_to :priority
        assert_should belong_to :sub_project

        assert_should have_many :mi_attempts
      end

      should 'have db columns' do
        assert_should have_db_column(:gene_id).with_options(:null => false)
        assert_should have_db_column(:consortium_id).with_options(:null => false)
        assert_should have_db_column(:production_centre_id)
        assert_should have_db_column(:status_id).with_options(:null => false)
        assert_should have_db_column(:priority_id).with_options(:null => false)
        assert_should have_db_column(:sub_project_id).with_options(:null => false)
        assert_should have_db_column(:is_bespoke_allele)
      end

      context '#latest_relevant_mi_attempt' do
        def ip; MiAttemptStatus.micro_injection_in_progress.description; end
        def co; MiAttemptStatus.chimeras_obtained.description; end
        def gc; MiAttemptStatus.genotype_confirmed.description; end
        def abrt; MiAttemptStatus.micro_injection_aborted.description; end

        should 'get active MI with latest in_progress_date if active one exists' do
          cbx1 = Factory.create :gene_cbx1
          inactive_mi = Factory.create :mi_attempt,
                  :colony_name => 'A',
                  :consortium_name => 'BaSH',
                  :production_centre_name => 'WTSI',
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :mi_date => '2011-12-12',
                  :is_active => false
          replace_status_stamps(inactive_mi,
            ip => '2011-10-10 00:00 UTC',
            abrt => Time.now
          )

          older_mi_1 = Factory.create :mi_attempt,
                  :colony_name => 'C',
                  :consortium_name => 'BaSH',
                  :production_centre_name => 'WTSI',
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :mi_date => '2011-12-12',
                  :is_active => true
          replace_status_stamps(older_mi_1,
            ip => '2011-03-02 00:00 UTC'
          )

          latest_mi = Factory.create :mi_attempt,
                  :colony_name => 'B',
                  :consortium_name => 'BaSH',
                  :production_centre_name => 'WTSI',
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :mi_date => '2011-12-12',
                  :is_active => true
          replace_status_stamps(latest_mi,
            ip => '2011-11-02 00:00 UTC'
          )

          older_mi_2 = Factory.create :mi_attempt,
                  :colony_name => 'D',
                  :consortium_name => 'BaSH',
                  :production_centre_name => 'WTSI',
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :mi_date => '2011-12-13',
                  :is_active => true
          replace_status_stamps(older_mi_2,
            ip => '2011-09-02 00:00 UTC'
          )

          mi_plan = older_mi_1.mi_plan

          assert older_mi_1.id < latest_mi.id, 'This is needed to test part of the association'
          assert_equal inactive_mi.mi_plan, latest_mi.mi_plan
          assert_equal latest_mi.mi_plan, older_mi_1.mi_plan
          mi_plan.reload
          assert_equal latest_mi.colony_name, mi_plan.latest_relevant_mi_attempt.colony_name
        end

        should 'get latest inactive MI if no active ones exist' do
          cbx1 = Factory.create :gene_cbx1
          older_mi = Factory.create :mi_attempt,
                  :colony_name => 'A',
                  :consortium_name => 'BaSH',
                  :production_centre_name => 'WTSI',
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :is_active => false
          replace_status_stamps(older_mi,
            ip => '2011-05-05 00:00 UTC',
            abrt => '2011-06-05 00:00 UTC'
          )

          latest_mi = Factory.create :mi_attempt,
                  :colony_name => 'B',
                  :consortium_name => 'BaSH',
                  :production_centre_name => 'WTSI',
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :is_active => false
          replace_status_stamps(latest_mi,
            ip => '2011-11-02 00:00 UTC',
            abrt => '2011-12-02 00:00 UTC'
          )
          mi_plan = older_mi.mi_plan

          assert older_mi.id < latest_mi.id, 'This is needed to test part of the association'
          assert_equal latest_mi.mi_plan, older_mi.mi_plan
          assert_equal latest_mi.mi_date, mi_plan.latest_relevant_mi_attempt.mi_date
        end

        should 'return nil if none' do
          mi_plan = Factory.create :mi_plan
          assert_nil mi_plan.latest_relevant_mi_attempt
        end

        should 'return GC MIs ahead of others regardless of their date' do
          cbx1 = Factory.create :gene_cbx1

          abrt_mi = Factory.create :mi_attempt,
                  :colony_name => 'Z',
                  :consortium_name => 'BaSH',
                  :production_centre_name => 'WTSI',
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :is_active => false
          replace_status_stamps(abrt_mi,
            ip => '2012-02-02 00:00 UTC',
            abrt => '2012-04-02 00:00 UTC'
          )

          ip_mi = Factory.create :mi_attempt,
                  :colony_name => 'D',
                  :consortium_name => 'BaSH',
                  :production_centre_name => 'WTSI',
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :is_active => true
          replace_status_stamps(ip_mi,
            ip => '2012-01-02 00:00 UTC'
          )

          latest_mi = Factory.create :wtsi_mi_attempt_genotype_confirmed,
                  :colony_name => 'C',
                  :consortium_name => 'BaSH',
                  :production_centre_name => 'WTSI',
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :is_active => true
          replace_status_stamps(latest_mi,
            ip => '2011-05-05 00:00 UTC',
            co => '2011-06-05',
            gc => '2011-07-05 00:00 UTC'
          )

          older_mi_1 = Factory.create :wtsi_mi_attempt_genotype_confirmed,
                  :colony_name => 'B',
                  :consortium_name => 'BaSH',
                  :production_centre_name => 'WTSI',
                  :is_released_from_genotyping => true,
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :is_active => true
          replace_status_stamps(older_mi_1,
            ip => '2011-04-05 00:00 UTC',
            co => '2011-05-05',
            gc => '2011-06-05 00:00 UTC'
          )

          mi_plan = latest_mi.mi_plan
          assert [latest_mi.mi_plan, ip_mi.mi_plan, older_mi_1.mi_plan].uniq.size == 1
          assert_equal 'C', mi_plan.latest_relevant_mi_attempt.colony_name
        end

        should 'return CO MIs ahead of IP or aborted ones regardless of their date' do
          cbx1 = Factory.create :gene_cbx1

          abrt_mi = Factory.create :mi_attempt,
                  :colony_name => 'Z',
                  :consortium_name => 'BaSH',
                  :production_centre_name => 'WTSI',
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :total_male_chimeras => 1,
                  :is_active => false
          replace_status_stamps(abrt_mi,
            ip => '2012-02-02 00:00 UTC',
            co => '2012-03-02',
            abrt => '2012-04-02 00:00 UTC'
          )

          ip_mi = Factory.create :mi_attempt,
                  :colony_name => 'D',
                  :consortium_name => 'BaSH',
                  :production_centre_name => 'WTSI',
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :is_active => true
          replace_status_stamps(ip_mi,
            ip => '2012-01-02 00:00 UTC'
          )

          latest_mi = Factory.create :mi_attempt,
                  :colony_name => 'C',
                  :consortium_name => 'BaSH',
                  :production_centre_name => 'WTSI',
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :total_male_chimeras => 1,
                  :is_active => true
          replace_status_stamps(latest_mi,
            ip => '2011-05-05 00:00 UTC',
            co => '2011-07-05'
          )

          older_mi_1 = Factory.create :mi_attempt,
                  :colony_name => 'B',
                  :consortium_name => 'BaSH',
                  :production_centre_name => 'WTSI',
                  :total_male_chimeras => 1,
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :is_active => true
          replace_status_stamps(older_mi_1,
            ip => '2011-04-05 00:00 UTC',
            co => '2011-06-05'
          )

          mi_plan = latest_mi.mi_plan
          assert [latest_mi.mi_plan, ip_mi.mi_plan, older_mi_1.mi_plan].uniq.size == 1
          assert_equal 'C', mi_plan.latest_relevant_mi_attempt.colony_name
        end
      end

      context '#status_stamps' do
        should 'be a valid association' do
          assert_should have_many :status_stamps
        end

        should 'be "Interest" by default' do
          mi_plan = Factory.create :mi_plan
          assert_equal [MiPlan::Status[:Interest]], mi_plan.status_stamps.map(&:status)
        end

        should 'be ordered by created_at asc' do
          default_mi_plan.status_stamps.destroy_all
          s1 = MiPlan::StatusStamp.create!(:mi_plan => default_mi_plan,
            :status => MiPlan::Status[:Assigned], :created_at => 1.day.ago)
          s2 = MiPlan::StatusStamp.create!(:mi_plan => default_mi_plan,
            :status => MiPlan::Status[:Conflict], :created_at => 1.hour.ago)
          s3 = MiPlan::StatusStamp.create!(:mi_plan => default_mi_plan,
            :status => MiPlan::Status[:Interest], :created_at => 12.hours.ago)
          default_mi_plan.status_stamps.reload
          assert_equal [s1, s3, s2].map(&:name), default_mi_plan.status_stamps.map(&:name)
        end

        should 'delete related MiPlan::StatusStamps as well' do
          plan = Factory.create :mi_plan_with_production_centre
          plan.status = MiPlan::Status['Conflict']; plan.save!
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
          default_mi_plan.status_stamps.destroy_all
          default_mi_plan.send(:add_status_stamp, MiPlan::Status[:Assigned])
          default_mi_plan.send(:add_status_stamp, MiPlan::Status[:Conflict])
        end

        should 'add the stamp' do
          assert_not_equal [], MiPlan::StatusStamp.where(
            :mi_plan_id => default_mi_plan.id,
            :status_id => MiPlan::Status[:Assigned].id)
          assert_not_equal [], MiPlan::StatusStamp.where(
            :mi_plan_id => default_mi_plan.id,
            :status_id => MiPlan::Status[:Conflict].id)
        end

        should 'update the association afterwards' do
          assert_equal [MiPlan::Status[:Assigned], MiPlan::Status[:Conflict]],
                  default_mi_plan.status_stamps.map(&:status)
        end
      end

      should 'have #phenotype_attempts' do
        assert_should have_many :phenotype_attempts
      end

      context '#reportable_statuses_with_latest_dates' do
        should 'work' do
          plan = Factory.create :mi_plan_with_production_centre

          plan.status_stamps.first.update_attributes!(:created_at => '2011-11-30 00:00:00')
          plan.reload
          plan.status_stamps.create!(:status => MiPlan::Status['Interest'],
            :created_at => '2010-10-30 23:59:59')
          plan.status_stamps.create!(:status => MiPlan::Status['Conflict'],
            :created_at => '2010-11-24 23:59:59')
          plan.status_stamps.create!(:status => MiPlan::Status['Conflict'],
            :created_at => '2011-05-30 23:59:59')
          plan.status_stamps.create!(:status => MiPlan::Status['Inspect - GLT Mouse'],
            :created_at => '2011-11-03 12:33:15')
          plan.status_stamps.create!(:status => MiPlan::Status['Inspect - GLT Mouse'],
            :created_at => '2011-02-12 23:59:59')
          plan.status_stamps.create!(:status => MiPlan::Status['Inactive'],
            :created_at => '2011-10-24 23:59:59')

          expected = {
            'Interest' => Date.parse('2011-11-30'),
            'Conflict' => Date.parse('2011-05-30'),
            'Inspect - GLT Mouse' => Date.parse('2011-11-03'),
            'Inactive' => Date.parse('2011-10-24')
          }

          assert_equal expected, plan.reportable_statuses_with_latest_dates
        end
      end

      context '#status' do
        should 'create status stamps when status is changed' do
          default_mi_plan.status = MiPlan::Status['Conflict']; default_mi_plan.save!
          default_mi_plan.status = MiPlan::Status['Assigned']; default_mi_plan.save!
          default_mi_plan.status = MiPlan::Status['Interest']; default_mi_plan.save!

          expected = ['Interest', 'Conflict', 'Assigned', 'Interest']
          assert_equal expected, default_mi_plan.status_stamps.map{|i| i.status.name}
        end

        should 'not add the same status stamp consecutively' do
          default_mi_plan.status = MiPlan::Status['Interest']; default_mi_plan.save!
          default_mi_plan.status = MiPlan::Status['Interest']; default_mi_plan.save!

          assert_equal ['Interest'], default_mi_plan.status_stamps.map{|i|i.status.name}
        end

        should 'not be one of the following if it has any phenotype attempts' do
          pt = Factory.create :phenotype_attempt
          plan = pt.mi_plan
          plan.status = MiPlan::Status['Assigned']
          plan.save!
          ["Interest","Conflict","Inspect - GLT Mouse","Inspect - MI Attempt","Inspect - Conflict","Aborted - ES Cell QC Failed","Withdrawn"].each do |this_status|
            plan.status = MiPlan::Status[this_status]
            plan.valid?
            assert_contains plan.errors[:status], /cannot be changed/, "for Status :: #{this_status}"
          end
        end

        should 'not be one of the following if it has any microinjection attempts' do
          mi_attempt = Factory.create :mi_attempt
          plan = mi_attempt.mi_plan
          plan.status = MiPlan::Status['Assigned']
          plan.save!
          ["Interest","Conflict","Inspect - GLT Mouse","Inspect - MI Attempt","Inspect - Conflict","Aborted - ES Cell QC Failed","Withdrawn"].each do |this_status|
            plan.status = MiPlan::Status[this_status]
            plan.valid?
            assert_contains plan.errors[:status], /cannot be changed/, "for Status :: #{this_status}"
          end
        end
      end

      context '#number_of_es_cells_starting_qc' do
        should 'exist' do
          assert_should have_db_column(:number_of_es_cells_starting_qc).of_type(:integer)
        end

        should 'be set same value as number passing QC if it is null' do
          assert_nil default_mi_plan.number_of_es_cells_starting_qc
          assert_nil default_mi_plan.number_of_es_cells_passing_qc

          default_mi_plan.number_of_es_cells_passing_qc = 7
          default_mi_plan.valid?
          assert_equal 7, default_mi_plan.number_of_es_cells_starting_qc

          default_mi_plan.number_of_es_cells_passing_qc = 2
          default_mi_plan.valid?
          assert_equal 7, default_mi_plan.number_of_es_cells_starting_qc
        end
      end

      context '#number_of_es_cells_passing_qc' do
        should 'exist' do
          assert_should have_db_column(:number_of_es_cells_passing_qc).of_type(:integer)
        end
      end

      context '#sub_project' do
        should 'be set to default when not set' do
          mi_plan = Factory.create :mi_plan
          assert_equal '', mi_plan.sub_project.name
        end

        should 'not be set to default when set' do
          mi_plan = Factory.create :mi_plan, :sub_project_id => 3
          assert_equal 3, mi_plan.sub_project.id
        end
      end

      context '#withdrawn virtual attribute' do
        context 'when being set to true' do
          should 'set the status to Withdrawn if it at an allowed status' do
            default_mi_plan.status = MiPlan::Status['Conflict']
            default_mi_plan.withdrawn = true
            assert_equal true, default_mi_plan.withdrawn
            assert_equal 'Withdrawn', default_mi_plan.status.name

            default_mi_plan.status = MiPlan::Status['Inspect - Conflict']
            default_mi_plan.withdrawn = true
            assert_equal true, default_mi_plan.withdrawn
            assert_equal 'Withdrawn', default_mi_plan.status.name
          end

          should 'raise an error if not at an allowed status' do
            default_mi_plan.status = MiPlan::Status['Assigned']
            assert_raise RuntimeError, 'cannot withdraw from status Assigned' do
              default_mi_plan.withdrawn = true
            end
            assert_equal false, default_mi_plan.withdrawn
            assert_equal 'Assigned', default_mi_plan.status.name
          end
        end

        context 'when being set to false' do
          should 'not allow it if withdrawn' do
            default_mi_plan.status = MiPlan::Status['Conflict']
            default_mi_plan.withdrawn = true
            assert_raise RuntimeError, 'withdrawal cannot be reversed' do
              default_mi_plan.withdrawn = false
            end
          end

          should 'allow it if not already withdrawn' do
            assert_nothing_raised do
              default_mi_plan.withdrawn = false
            end
          end
        end

        should 'return true if status is Withdrawn' do
          default_mi_plan.status = MiPlan::Status['Withdrawn']
          assert_equal true, default_mi_plan.withdrawn
        end

        should 'return false if status is not Withdrawn' do
          default_mi_plan.status = MiPlan::Status['Assigned']
          assert_equal false, default_mi_plan.withdrawn
          default_mi_plan.status = MiPlan::Status['Conflict']
          assert_equal false, default_mi_plan.withdrawn
        end

        should 'be readable as #withdrawn?' do
          assert_false default_mi_plan.withdrawn?
          default_mi_plan.status = MiPlan::Status['Conflict']
          default_mi_plan.withdrawn = true
          assert_true default_mi_plan.withdrawn?
        end
      end

      should 'validate logical key - the uniqueness of gene for a consortium and production_centre' do
        plan = Factory.create :mi_plan
        plan.save!

        plan2 = Factory.build(:mi_plan,
          :gene => plan.gene, :consortium => plan.consortium)
        assert_false plan2.save

        assert_false plan2.valid?
        assert_match /already has/, plan2.errors['gene'].first

        plan.production_centre = Centre.find_by_name!('WTSI')
        plan.save!

        plan2.production_centre = plan.production_centre
        assert_false plan2.valid?
        assert_match /already has/, plan2.errors['gene'].first
      end

      context '#is_active' do
        should 'exist' do
          assert_should have_db_column(:is_active).with_options(:null => false, :default => true)
        end

        should 'be true if an active microinjection attempt found' do
          active_mi = Factory.create :mi_attempt, :is_active => true
          active_mi.mi_plan.is_active = false
          active_mi.mi_plan.valid?
          assert_match /cannot be set to false as active micro-injection attempt/, active_mi.mi_plan.errors[:is_active].first
        end

        should 'be true if an active phenotype attempt found' do
          gene = Factory.create :gene_cbx1
          inactive_plan = Factory.create :mi_plan, :gene => gene, :is_active => true
          active_mi_attempt = Factory.create :mi_attempt_genotype_confirmed, :es_cell => Factory.create(:es_cell, :gene => gene)
          active_pa = Factory.create :phenotype_attempt, :is_active => true, :mi_attempt => active_mi_attempt, :mi_plan => inactive_plan
          inactive_plan.is_active = false
          inactive_plan.valid?
          assert_contains inactive_plan.errors[:is_active], /cannot be set to false as active phenotype attempt/
        end
      end
    end # attribute tests

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
            :status => MiPlan::Status.find_by_name!('Inspect - Conflict')),
          Factory.create(:mi_plan, :gene => gene,
            :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'),
            :status => MiPlan::Status.find_by_name!('Inspect - Conflict'))
        ]

        MiPlan.major_conflict_resolution
        @only_interest_mi_plan.reload
        @inspect_mi_plans.each(&:reload)
      end

      should 'set Interested MiPlan to Assigned status if no other Interested or Assigned MiPlan for the same gene exists' do
        setup_for_set_one_to_assigned
        assert_equal 'Assigned', @only_interest_mi_plan.status.name
        MiPlan.major_conflict_resolution
      end

      should 'not affect non-Interested MiPlans when setting Interested ones to Assigned' do
        setup_for_set_one_to_assigned
        assert_equal ['Inspect - Conflict', 'Inspect - Conflict'], @inspect_mi_plans.map{|i| i.status.name}
        MiPlan.major_conflict_resolution
      end

      should 'set all Interested MiPlans that have the same gene to Conflict' do
        gene = Factory.create :gene_cbx1
        mi_plans = ['BaSH', 'MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!(consortium_name)
        end

        MiPlan.major_conflict_resolution

        mi_plans.each(&:reload)
        assert_equal ['Conflict', 'Conflict', 'Conflict'], mi_plans.map {|i| i.status.name }

        MiPlan.major_conflict_resolution
      end

      should 'set all Interested MiPlans to Conflict if other MiPlans for the same gene are in Conflict' do
        gene = Factory.create :gene_cbx1
        mi_plans = ['MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene,
                  :consortium => Consortium.find_by_name!(consortium_name),
                  :status => MiPlan::Status.find_by_name!('Conflict')
        end

        interested_mi_plan = Factory.create :mi_plan,
                :gene => gene, :consortium => Consortium.find_by_name!('BaSH')

        MiPlan.major_conflict_resolution
        interested_mi_plan.reload

        assert_equal 'Conflict', interested_mi_plan.status.name

        MiPlan.major_conflict_resolution
      end

      should 'set all interested MiPlans to "Inspect - Conflict" if other MiPlans for the same gene are already Assigned' do
        gene = Factory.create :gene_cbx1
        Factory.create :mi_plan, :gene => gene,
                :consortium => Consortium.find_by_name!('BaSH'),
                :status => MiPlan::Status.find_by_name!('Assigned')

        mi_plans = ['MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!(consortium_name)
        end

        MiPlan.major_conflict_resolution
        mi_plans.each(&:reload)

        assert_equal ['Inspect - Conflict', 'Inspect - Conflict'], mi_plans.map {|i| i.status.name }
      end

      should 'set all interested MiPlans to "Inspect - Conflict" if other MiPlans for the same gene are already in an alternative Assigned state (like the ES Cell QC ones)' do
        gene = Factory.create :gene_cbx1
        plan = Factory.create :mi_plan, :gene => gene,
                :consortium => Consortium.find_by_name!('BaSH'),
                :number_of_es_cells_starting_qc => 5
        assert_equal 'Assigned - ES Cell QC In Progress', plan.status.name

        mi_plans = ['MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!(consortium_name)
        end

        MiPlan.major_conflict_resolution
        mi_plans.each(&:reload)

        assert_equal ['Inspect - Conflict', 'Inspect - Conflict'], mi_plans.map {|i| i.status.name }
      end

      should 'set all interested MiPlans to "Inspect - MI Attempt" if MiPlans with active MiAttempts already exist' do
        gene = Factory.create :gene_cbx1
        mi_plan = Factory.create :mi_plan,
                :gene              => gene,
                :consortium        => Consortium.find_by_name!('BaSH'),
                :status    => MiPlan::Status.find_by_name!('Assigned'),
                :production_centre => Centre.find_by_name!('BCM')

        mi_attempt = Factory.create(:mi_attempt, :es_cell => Factory.create(:es_cell, :gene => gene),
          :consortium_name => 'BaSH', :production_centre_name => 'BCM')

        assert_equal mi_plan, mi_attempt.mi_plan

        mi_plans = ['MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!(consortium_name)
        end

        MiPlan.major_conflict_resolution
        mi_plans.each(&:reload)

        assert_equal ['Inspect - MI Attempt', 'Inspect - MI Attempt'], mi_plans.map {|i| i.status.name }
      end

      should 'set all interested MiPlans to "Inspect - GLT Mouse" if MiPlans with Genotype Confirmed MIs already exist' do
        gene = Factory.create :gene_cbx1
        mi_plan = Factory.create :mi_plan,
                :gene              => gene,
                :consortium        => Consortium.find_by_name!('BaSH'),
                :status    => MiPlan::Status.find_by_name!('Assigned'),
                :production_centre => Centre.find_by_name!('BCM')

        mi_attempt = Factory.create :mi_attempt,
                :es_cell                  => Factory.create(:es_cell, :gene => gene),
                :consortium_name          => 'BaSH',
                :production_centre_name   => 'BCM'
        set_mi_attempt_genotype_confirmed(mi_attempt)

        assert_equal mi_plan, mi_attempt.mi_plan
        assert_equal MiAttemptStatus.genotype_confirmed.description, mi_attempt.status

        mi_plans = ['MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!(consortium_name)
        end

        mi_plans.each { |plan| assert_equal 'Interest', plan.status.name }

        MiPlan.major_conflict_resolution
        mi_plans.each(&:reload)

        assert_equal ['Inspect - GLT Mouse', 'Inspect - GLT Mouse'], mi_plans.map {|i| i.status.name }
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
                :status => MiPlan::Status['Inactive']

        assert_equal 'Interest', mi_plan.status.name
        assert_equal 'Inactive', inactive_mi_plan.status.name

        MiPlan.major_conflict_resolution

        assert_equal 'Assigned', mi_plan.reload.status.name
        assert_equal 'Inactive', inactive_mi_plan.reload.status.name
      end

    end # ::major_conflict_resolution

    context '::minor_conflict_resolution' do
      should 'not change status of any assigned MiPlans' do
        plan = Factory.create :mi_plan_with_production_centre,
                :number_of_es_cells_starting_qc => 4
        assert plan.assigned?
        MiPlan.minor_conflict_resolution
        plan.reload
        assert_equal 'Assigned - ES Cell QC In Progress', plan.status.name
      end

      [
        'Conflict',
        'Inspect - Conflict',
        'Inspect - MI Attempt',
        'Inspect - GLT Mouse'
      ].each do |status_name|
        should "Assign an MiPlan in status #{status_name} if it is the only one for a gene" do
          plan = Factory.create :mi_plan_with_production_centre,
                  :status => MiPlan::Status[status_name]
          MiPlan.minor_conflict_resolution
          plan.reload
          assert_equal 'Assigned', plan.status.name
        end

        should "not Assign MiPlan in status #{status_name} if an Assigned one exists for that gene" do
          gene = Factory.create :gene_cbx1
          Factory.create :mi_plan_with_production_centre,
                  :number_of_es_cells_passing_qc => 2,
                  :gene => gene
          plan = Factory.create :mi_plan_with_production_centre,
                  :status => MiPlan::Status[status_name],
                  :gene => gene
          MiPlan.minor_conflict_resolution
          plan.reload
          assert_equal status_name, plan.status.name
        end
      end

      [
        'Interest',
        'Withdrawn',
        'Aborted - ES Cell QC Failed'
      ].each do |status_name|
        should "not change the status of MiPlan with status #{status_name} even if it is the only one for a gene" do
          plan = Factory.create :mi_plan_with_production_centre,
                  :status => MiPlan::Status[status_name]
          MiPlan.minor_conflict_resolution
          plan.reload
          assert_equal status_name, plan.status.name
        end
      end

      should 'not change status of Inspect or Conflict MiPlans if there are more than one of them for a gene' do
        gene = Factory.create :gene_cbx1
        plan1 = Factory.create :mi_plan_with_production_centre,
                :status => MiPlan::Status['Conflict'],
                :gene => gene
        plan2 = Factory.create :mi_plan_with_production_centre,
                :status => MiPlan::Status['Inspect - MI Attempt'],
                :gene => gene
        MiPlan.minor_conflict_resolution
        plan1.reload; plan2.reload
        assert_equal 'Conflict', plan1.status.name
        assert_equal 'Inspect - MI Attempt', plan2.status.name
      end

      should 'change the status of a Conflct MiPlan if it is the only one for a gene' do
        gene = Factory.create :gene_cbx1
        conflict_plan = Factory.create :mi_plan_with_production_centre,
                :status => MiPlan::Status['Conflict'],
                :gene => gene

        MiPlan.minor_conflict_resolution

        conflict_plan.reload
        assert_equal 'Assigned', conflict_plan.status.name
      end
    end # ::minor_conflict_resolution

    context '::all_grouped_by_mgi_accession_id_then_by_status_name' do
      should 'work' do
        Factory.create :consortium, :name => 'Consortium X'
        gene1 = Factory.create :gene_cbx1
        gene2 = Factory.create :gene_trafd1
        bash = Factory.create :mi_plan, :gene => gene1,
                :consortium => Consortium.find_by_name!('BaSH'),
                :status => MiPlan::Status.find_by_name!('Interest')
        consortium_x = Factory.create :mi_plan, :gene => gene1,
                :consortium => Consortium.find_by_name!('Consortium X'),
                :status => MiPlan::Status.find_by_name!('Interest')
        mgp = Factory.create :mi_plan, :gene => gene1,
                :consortium => Consortium.find_by_name!('MGP'),
                :status => MiPlan::Status.find_by_name!('Assigned')
        eucomm = Factory.create :mi_plan, :gene => gene2,
                :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'),
                :status => MiPlan::Status.find_by_name!('Inspect - Conflict')

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
        assert_equal 20, MiPlan.count
        assert_equal 10, MiPlan.with_mi_attempt.count
      end
    end

    context '::with_active_mi_attempt' do
      should 'work' do
        10.times { Factory.create :mi_plan }
        10.times { Factory.create :mi_attempt, :is_active => true }
        10.times { Factory.create :mi_attempt, :is_active => false }

        assert MiPlan.count > MiPlan.with_active_mi_attempt.count
        assert_equal 30, MiPlan.count
        assert_equal 10, MiPlan.with_active_mi_attempt.count
      end
    end

    context '::without_mi_attempt' do
      should 'work' do
        10.times { Factory.create :mi_plan }
        10.times { Factory.create :mi_attempt }

        assert MiPlan.count > MiPlan.without_mi_attempt.count
        assert_equal 20, MiPlan.count
        assert_equal 10, MiPlan.without_mi_attempt.count
      end
    end

    context '::without_active_mi_attempt' do
      should 'work' do
        10.times { Factory.create :mi_plan }
        10.times { Factory.create :mi_attempt, :is_active => true }
        10.times { Factory.create :mi_attempt, :is_active => false }

        assert MiPlan.count > MiPlan.without_active_mi_attempt.count
        assert_equal 30, MiPlan.count
        assert_equal 20, MiPlan.without_active_mi_attempt.count
      end
    end

    context '::with_genotype_confirmed_mouse' do
      should 'work' do
        10.times { Factory.create :mi_plan }
        10.times { Factory.create :mi_attempt, :is_active => true }
        10.times do
          mi = Factory.create :mi_attempt,
                  :production_centre_name => 'ICS',
                  :is_active => true
          set_mi_attempt_genotype_confirmed(mi)
        end

        assert MiPlan.count > MiPlan.with_genotype_confirmed_mouse.count
        assert_equal 30, MiPlan.count
        assert_equal 10, MiPlan.with_genotype_confirmed_mouse.count
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
        plan.status = MiPlan::Status['Assigned']
        assert plan.assigned?

        plan.status = MiPlan::Status['Assigned - ES Cell QC In Progress']
        assert plan.assigned?

        plan.status = MiPlan::Status['Assigned - ES Cell QC Complete']
        assert plan.assigned?
      end

      should 'return false if status is not assigned' do
        plan = Factory.build :mi_plan_with_production_centre
        plan.status = MiPlan::Status['Inactive']
        assert_false plan.assigned?

        plan.status = MiPlan::Status['Conflict']
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
        mi_plan.reload; assert_equal 'Inspect - GLT Mouse', mi_plan.status.name

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
        mi_plan.reload; assert_equal 'Inspect - MI Attempt', mi_plan.status.name

        assert_equal "MI already in progress at: #{@ics_cent.name} (#{@eucomm_cons.name}), #{@jax_cent.name} (#{@bash_cons.name})",
                mi_plan.reason_for_inspect_or_conflict
      end

      should 'correctly return for Inspect - Conflict' do
        Factory.create :mi_attempt

        Factory.create :mi_plan, :gene => @gene,
                :consortium => @eucomm_cons, :production_centre => @ics_cent,
                :status => MiPlan::Status[:Assigned]

        Factory.create :mi_plan, :gene => @gene,
                :consortium => @bash_cons, :production_centre => @jax_cent,
                :number_of_es_cells_starting_qc => 5

        mi_plan = Factory.create :mi_plan, :gene => @gene,
                :consortium => @mgp_cons, :production_centre => @cnb_cent

        MiPlan.major_conflict_resolution
        mi_plan.reload; assert_equal 'Inspect - Conflict', mi_plan.status.name

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
        mi_plan.reload; assert_equal 'Conflict', mi_plan.status.name

        assert_equal "Other MI plans for: #{@eucomm_cons.name}, #{@bash_cons.name}",
                mi_plan.reason_for_inspect_or_conflict
      end

      should 'return nil if no conflict' do
        mi_plan = Factory.create :mi_plan
        assert_nil mi_plan.reason_for_inspect_or_conflict
      end
    end

    context '#latest_relevant_phenotype_attempt' do
      should 'return nil if there are no phenotype attempts for this MI' do
        assert_equal nil, default_mi_plan.latest_relevant_phenotype_attempt
      end

      should 'return the latest created active one if there are any active phenotype attempts' do
        mi_attempt = Factory.create :mi_attempt_genotype_confirmed,
                :es_cell => Factory.create(:es_cell, :gene => default_mi_plan.gene)
        Factory.create :phenotype_attempt, :mi_plan => default_mi_plan,
                :created_at => "2011-12-02 23:59:59 UTC",
                :mi_attempt => mi_attempt
        pt = Factory.create :phenotype_attempt, :mi_plan => default_mi_plan,
                :created_at => "2011-12-03 23:59:59 UTC",
                :mi_attempt => mi_attempt
        Factory.create :phenotype_attempt, :mi_plan => default_mi_plan,
                :created_at => "2011-12-01 23:59:59 UTC",
                :mi_attempt => mi_attempt
        Factory.create :phenotype_attempt, :mi_plan => default_mi_plan,
                :created_at => "2011-12-10 23:59:59 UTC",
                :mi_attempt => mi_attempt, :is_active => false

        assert_equal pt, default_mi_plan.latest_relevant_phenotype_attempt
      end

      should 'return the latest created aborted one if all its phenotype attempts are aborted' do
        mi_attempt = Factory.create :mi_attempt_genotype_confirmed,
                :es_cell => Factory.create(:es_cell, :gene => default_mi_plan.gene)
        Factory.create :phenotype_attempt, :mi_plan => default_mi_plan,
                :created_at => '2011-12-02 23:59:59 UTC',
                :is_active => false, :mi_attempt => mi_attempt
        pt = Factory.create :phenotype_attempt, :mi_plan => default_mi_plan,
                :created_at => '2011-12-03 23:59:59 UTC',
                :is_active => false, :mi_attempt => mi_attempt
        Factory.create :phenotype_attempt, :mi_plan => default_mi_plan,
                :created_at => '2011-12-01 23:59:59 UTC',
                :is_active => false, :mi_attempt => mi_attempt

        assert_equal pt, default_mi_plan.latest_relevant_phenotype_attempt
      end
    end

    context '#distinct_old_genotype_confirmed_es_cells_count' do
      should 'work' do
        cbx1 = Factory.create :gene_cbx1

        mi_plan_args = {
          :consortium_name => 'BaSH',
          :production_centre_name => 'WTSI',
          :es_cell => Factory.create(:es_cell, :gene => cbx1)
        }

        mi_attempt1 = Factory.create(:wtsi_mi_attempt_genotype_confirmed, mi_plan_args)
        replace_status_stamps(mi_attempt1, [
          ['Genotype confirmed', '2011-05-13 05:04:01 UTC'],
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_attempt2 = Factory.create(:wtsi_mi_attempt_genotype_confirmed, mi_plan_args)
        replace_status_stamps(mi_attempt2, [
          ['Genotype confirmed', '2011-05-13 05:04:01 UTC'],
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_plan_args[:es_cell] = Factory.create(:es_cell, :gene => cbx1)
        mi_attempt3 = Factory.create(:wtsi_mi_attempt_genotype_confirmed, mi_plan_args)
        replace_status_stamps(mi_attempt3, [
          ['Genotype confirmed', '2011-05-13 05:04:01 UTC'],
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_plan_args[:es_cell] = Factory.create(:es_cell, :gene => cbx1)
        mi_attempt4 = Factory.create(:mi_attempt, mi_plan_args)
        replace_status_stamps(mi_attempt4, [
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_plan_args[:es_cell] = Factory.create(:es_cell, :gene => cbx1)
        newer_mi_attempt = Factory.create(:wtsi_mi_attempt_genotype_confirmed, mi_plan_args)

        mi_plan = mi_attempt1.mi_plan.reload
        result = mi_plan.distinct_old_genotype_confirmed_es_cells_count
        assert_equal 2, result
      end

      should 'not treat aborted MIs with a GC status stamp as GC' do
        cbx1 = Factory.create :gene_cbx1
        mi_plan_args = {
          :consortium_name => 'BaSH',
          :production_centre_name => 'WTSI',
          :es_cell => Factory.create(:es_cell, :gene => cbx1)
        }

        mi_attempt = Factory.create(:mi_attempt, :is_active => false)
        replace_status_stamps(mi_attempt,
          'Micro-injection in progress' => '2010-05-13',
          'Genotype confirmed' => '2010-11-12',
          'Micro-injection aborted' => '2010-12-11'
        )

        result = mi_attempt.mi_plan.distinct_old_genotype_confirmed_es_cells_count
        assert_equal 0, result
      end
    end

    context '#distinct_old_non_genotype_confirmed_es_cells_count' do
      should 'just work' do
        cbx1 = Factory.create :gene_cbx1

        mi_plan_args = {
          :consortium_name => 'BaSH',
          :production_centre_name => 'WTSI',
          :es_cell => Factory.create(:es_cell, :gene => cbx1)
        }

        mi_attempt1 = Factory.create(:mi_attempt, mi_plan_args)
        replace_status_stamps(mi_attempt1, [
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_attempt2 = Factory.create(:mi_attempt, mi_plan_args.merge(:is_active => false))
        replace_status_stamps(mi_attempt2, [
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC'],
          ['Micro-injection aborted', '2010-05-13 05:04:01 UTC'],
        ])

        mi_plan_args[:es_cell] = Factory.create(:es_cell, :gene => cbx1)
        mi_attempt3 = Factory.create(:mi_attempt, mi_plan_args)
        replace_status_stamps(mi_attempt3, [
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_plan_args[:es_cell] = Factory.create(:es_cell, :gene => cbx1)
        mi_attempt4 = Factory.create(:wtsi_mi_attempt_genotype_confirmed, mi_plan_args)
        replace_status_stamps(mi_attempt4, [
          ['Genotype confirmed', '2011-05-13 05:04:01 UTC'],
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_plan_args[:es_cell] = Factory.create(:es_cell, :gene => cbx1)
        newer_mi_attempt = Factory.create(:mi_attempt, mi_plan_args)

        mi_plan = mi_attempt1.mi_plan.reload
        result = mi_attempt1.mi_plan.distinct_old_non_genotype_confirmed_es_cells_count
        assert_equal 2, result
      end

      should 'not treat aborted MIs with a GC status stamp as GC' do
        cbx1 = Factory.create :gene_cbx1
        mi_plan_args = {
          :consortium_name => 'BaSH',
          :production_centre_name => 'WTSI',
          :es_cell => Factory.create(:es_cell, :gene => cbx1)
        }

        mi_attempt = Factory.create(:mi_attempt, :is_active => false)
        replace_status_stamps(mi_attempt,
          'Micro-injection in progress' => '2010-05-13',
          'Genotype confirmed' => '2010-11-12',
          'Micro-injection aborted' => '2010-12-11'
        )

        result = mi_attempt.mi_plan.distinct_old_non_genotype_confirmed_es_cells_count
        assert_equal 1, result
      end
    end

    context '#latest_relevant_status' do

      should 'find plan' do
        gene = Factory.create :gene_cbx1
        mi_plan = Factory.create(:mi_plan, :gene => gene,
          :consortium => Consortium.find_by_name!('MGP'),
          :status => MiPlan::Status.find_by_name!('Aborted - ES Cell QC Failed'))

        results = mi_plan.latest_relevant_status

        assert_equal "Aborted - ES Cell QC Failed", results[:status]
        assert_equal Date.today.to_date, results[:date].to_date
      end

      should 'find attempt' do
        mi_attempt = Factory.create(:mi_attempt, :is_active => false)

        results = mi_attempt.mi_plan.latest_relevant_status

        assert_equal "Micro-injection aborted", results[:status]
        assert_equal Date.today.to_date, results[:date].to_date
      end

      should 'find phenotype' do
        gene = Factory.create :gene_cbx1
        mi_plan = Factory.create :mi_plan, :gene => gene
        mi_attempt = Factory.create :mi_attempt_genotype_confirmed,
          :es_cell => Factory.create(:es_cell, :gene => gene)
        phenotype = Factory.create :phenotype_attempt, :mi_plan => mi_plan,
          :created_at => "2011-12-02",
          :mi_attempt => mi_attempt

        phenotype.status_stamps.create!(
          :status => PhenotypeAttempt::Status['Phenotype Attempt Registered'],
          :created_at => '2011-10-30')

        results = mi_plan.latest_relevant_status

        assert_equal "Phenotype Attempt Registered", results[:status]
        assert_equal Date.today.to_date, results[:date].to_date
      end

    end

    context '#relevant_status_stamp' do

      should 'find plan' do
        gene = Factory.create :gene_cbx1
        mi_plan = Factory.create(:mi_plan, :gene => gene,
          :consortium => Consortium.find_by_name!('MGP'),
          :status => MiPlan::Status.find_by_name!('Aborted - ES Cell QC Failed'))

        results = mi_plan.relevant_status_stamp

        assert_equal "aborted_es_cell_qc_failed", results[:status]
        assert_equal Date.today.to_date, results[:date].to_date
      end

      should 'find attempt' do
        mi_attempt = Factory.create(:mi_attempt, :is_active => false)

        results = mi_attempt.mi_plan.relevant_status_stamp

        assert_equal "microinjection_aborted", results[:status]
        assert_equal Date.today.to_date, results[:date].to_date
      end

      should 'find phenotype with earliest date stamp' do
        gene = Factory.create :gene_cbx1
        mi_plan = Factory.create :mi_plan, :gene => gene
        mi_attempt = Factory.create :mi_attempt_genotype_confirmed,
          :es_cell => Factory.create(:es_cell, :gene => gene)
        phenotype = Factory.create :phenotype_attempt, :mi_plan => mi_plan,
          :created_at => "2011-12-02",
          :mi_attempt => mi_attempt

        phenotype.status_stamps.create!(
          :status => PhenotypeAttempt::Status['Phenotype Attempt Registered'],
          :created_at => '2011-10-30')

        results = mi_plan.relevant_status_stamp

        assert_equal "phenotype_attempt_registered", results[:status]
        assert_equal Date.parse('2011-10-30').to_date, results[:date].to_date
      end

    end

  end
end
