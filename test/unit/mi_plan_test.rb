# encoding: utf-8

require 'test_helper'

class MiPlanTest < ActiveSupport::TestCase

  context 'MiPlan' do

    def default_mi_plan
      @default_mi_plan ||= Factory.create :mi_plan_with_production_centre
    end

    should 'default_mi_plan should be in state Assigned for the rest of the tests' do
      assert_equal 'Assigned', default_mi_plan.status.name
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
        assert_should have_db_column(:is_bespoke_allele).with_options(:null => false)
        assert_should have_db_column(:is_conditional_allele).with_options(:null => false)
        assert_should have_db_column(:is_deletion_allele).with_options(:null => false)
        assert_should have_db_column(:is_cre_knock_in_allele).with_options(:null => false)
        assert_should have_db_column(:is_cre_bac_allele).with_options(:null => false)
        assert_should have_db_column(:comment)
        assert_should have_db_column(:es_qc_comment_id)
      end

      context '#latest_relevant_mi_attempt' do
        def ip; MiAttempt::Status.micro_injection_in_progress.name; end
        def co; MiAttempt::Status.chimeras_obtained.name; end
        def gc; MiAttempt::Status.genotype_confirmed.name; end
        def abrt; MiAttempt::Status.micro_injection_aborted.name; end

        should 'get active MI with latest in_progress_date if active one exists' do
          assert cbx1
          plan = bash_wtsi_cbx1_plan

          inactive_mi = Factory.create :mi_attempt2,
                  :colony_name => 'A',
                  :mi_plan => plan,
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :mi_date => '2011-12-12',
                  :is_active => false
          replace_status_stamps(inactive_mi,
            'mip' => '2011-10-10 00:00 UTC',
            'abt' => Time.now
          )

          older_mi_1 = Factory.create :mi_attempt2,
                  :colony_name => 'C',
                  :mi_plan => plan,
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :mi_date => '2011-12-12',
                  :is_active => true
          replace_status_stamps(older_mi_1,
            'mip' => '2011-03-02 00:00 UTC'
          )

          latest_mi = Factory.create :mi_attempt2,
                  :colony_name => 'B',
                  :mi_plan => plan,
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :mi_date => '2011-12-12',
                  :is_active => true
          replace_status_stamps(latest_mi,
            'mip' => '2011-11-02 00:00 UTC'
          )

          older_mi_2 = Factory.create :mi_attempt2,
                  :colony_name => 'D',
                  :mi_plan => plan,
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :mi_date => '2011-12-13',
                  :is_active => true
          replace_status_stamps(older_mi_2,
            'mip' => '2011-09-02 00:00 UTC'
          )

          mi_plan = older_mi_1.mi_plan

          assert older_mi_1.id < latest_mi.id, 'This is needed to test part of the association'
          assert_equal inactive_mi.mi_plan, latest_mi.mi_plan
          assert_equal latest_mi.mi_plan, older_mi_1.mi_plan
          mi_plan.reload
          assert_equal latest_mi.colony_name, mi_plan.latest_relevant_mi_attempt.colony_name
        end

        should 'get latest inactive MI if no active ones exist' do
          assert cbx1
          older_mi = Factory.create :mi_attempt2,
                  :colony_name => 'A',
                  :mi_plan => bash_wtsi_cbx1_plan,
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :is_active => false
          replace_status_stamps(older_mi,
            ip => '2011-05-05 00:00 UTC',
            abrt => '2011-06-05 00:00 UTC'
          )

          latest_mi = Factory.create :mi_attempt2,
                  :colony_name => 'B',
                  :mi_plan => bash_wtsi_cbx1_plan,
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
          assert cbx1

          abrt_mi = Factory.create :mi_attempt2,
                  :colony_name => 'Z',
                  :mi_plan => bash_wtsi_cbx1_plan,
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :is_active => false
          replace_status_stamps(abrt_mi,
            ip => '2012-02-02 00:00 UTC',
            abrt => '2012-04-02 00:00 UTC'
          )

          ip_mi = Factory.create :mi_attempt2,
                  :colony_name => 'D',
                  :mi_plan => bash_wtsi_cbx1_plan,
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :is_active => true
          replace_status_stamps(ip_mi,
            ip => '2012-01-02 00:00 UTC'
          )

          latest_mi = Factory.create :mi_attempt2_status_gtc,
                  :colony_name => 'C',
                  :mi_plan => bash_wtsi_cbx1_plan,
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :is_active => true
          replace_status_stamps(latest_mi,
            ip => '2011-05-05 00:00 UTC',
            co => '2011-06-05',
            gc => '2011-07-05 00:00 UTC'
          )

          older_mi_1 = Factory.create :mi_attempt2_status_gtc,
                  :colony_name => 'B',
                  :mi_plan => bash_wtsi_cbx1_plan,
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
          assert cbx1

          abrt_mi = Factory.create :mi_attempt2,
                  :colony_name => 'Z',
                  :mi_plan => bash_wtsi_cbx1_plan,
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :total_male_chimeras => 1,
                  :is_active => false
          replace_status_stamps(abrt_mi,
            ip => '2012-02-02 00:00 UTC',
            co => '2012-03-02',
            abrt => '2012-04-02 00:00 UTC'
          )

          ip_mi = Factory.create :mi_attempt2,
                  :colony_name => 'D',
                  :mi_plan => bash_wtsi_cbx1_plan,
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :is_active => true
          replace_status_stamps(ip_mi,
            ip => '2012-01-02 00:00 UTC'
          )

          latest_mi = Factory.create :mi_attempt2_status_chr,
                  :colony_name => 'C',
                  :mi_plan => bash_wtsi_cbx1_plan,
                  :es_cell => Factory.create(:es_cell, :gene => cbx1),
                  :is_active => true
          replace_status_stamps(latest_mi,
            ip => '2011-05-05 00:00 UTC',
            co => '2011-07-05'
          )

          older_mi_1 = Factory.create :mi_attempt2_status_chr,
                  :colony_name => 'B',
                  :mi_plan => bash_wtsi_cbx1_plan,
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

        should 'be "Assigned" by default' do
          mi_plan = Factory.create :mi_plan
          assert_equal [MiPlan::Status[:Assigned]], mi_plan.status_stamps.map(&:status)
        end

        should 'be deleted when MiPlan is deleted' do
          plan = Factory.create :mi_plan
          plan.number_of_es_cells_starting_qc = 5; plan.save!
          stamps = plan.status_stamps.dup
          assert_equal 2, stamps.size

          plan.destroy

          stamps = stamps.map {|s| MiPlan::StatusStamp.find_by_id s.id}
          assert_equal [nil, nil], stamps
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

          plan.status_stamps.destroy_all

          plan.status_stamps.create!(:status => MiPlan::Status['Interest'],
            :created_at => '2010-10-30 23:59:59')
          plan.status_stamps.create!(:status => MiPlan::Status['Conflict'],
            :created_at => '2011-05-30 23:59:59')
          plan.status_stamps.create!(:status => MiPlan::Status['Inspect - GLT Mouse'],
            :created_at => '2011-11-03 00:00:00 UTC')
          plan.status_stamps.create!(:status => MiPlan::Status['Inactive'],
            :created_at => '2011-10-24 23:59:59')

          expected = {
            'Interest' => Date.parse('2010-10-30'),
            'Conflict' => Date.parse('2011-05-30'),
            'Inspect - GLT Mouse' => Date.parse('2011-11-03'),
            'Inactive' => Date.parse('2011-10-24')
          }

          assert_equal expected, plan.reportable_statuses_with_latest_dates
        end
      end

      context '#status' do
        should 'create status stamps when status is changed' do
          default_mi_plan.is_active = false
          default_mi_plan.save!

          replace_status_stamps(default_mi_plan,
            :Assigned => '2012-01-01',
            :Inactive => '2012-01-02')

          expected = ["Assigned", "Inactive"]
          assert_equal expected, default_mi_plan.status_stamps.map{|i| i.status.name}
        end

        should 'not add the same status stamp consecutively' do
          default_mi_plan.update_attributes!(:number_of_es_cells_starting_qc => 2)
          default_mi_plan.save!

          assert_equal ['asg', 'asg-esp'], default_mi_plan.status_stamps.map{|i|i.status.code}
        end

        should 'not be a non-assigned status if it has any phenotype attempts' do
          mi = Factory.create :mi_attempt2_status_gtc, :mi_plan => TestDummy.mi_plan('DTCC', 'UCD', :gene => cbx1, :force_assignment => true)
          plan = bash_wtsi_cbx1_plan(:force_assignment => true)
          pt = Factory.create :phenotype_attempt, :mi_plan => plan, :mi_attempt => mi
          plan.reload
          assert_equal 0, plan.mi_attempts.count
          assert_equal 1, plan.phenotype_attempts.count

          plan.withdrawn = true; plan.valid?
          assert_contains plan.errors[:status], /cannot be changed/
        end

        should 'not be a non-assigned status if it has any micro-injection attempts' do
          mi_attempt = Factory.create :mi_attempt2
          plan = mi_attempt.mi_plan

          plan.withdrawn = true; plan.valid?
          assert_contains plan.errors[:status], /cannot be changed/
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

      context '#withdrawn' do
        should 'not be settable if currently not in an allowed status' do
          default_mi_plan.withdrawn = true
          assert_false default_mi_plan.valid?
          assert_match(/cannot be set/, default_mi_plan.errors[:withdrawn].first)
        end

        should 'be settable on a new record' do
          plan = Factory.create :mi_plan, :withdrawn => true
          assert_equal 'Withdrawn', plan.status.name
        end
      end

      should 'validate logical key - the uniqueness of gene for a consortium, production_centre and sub project' do
        plan = Factory.create :mi_plan
        plan.save!

        plan2 = Factory.build(:mi_plan,
          :gene => plan.gene, :consortium => plan.consortium, :sub_project => plan.sub_project)
        assert_false plan2.save

        assert_false plan2.valid?
        assert_match(/already has/, plan2.errors['gene'].first)

        plan.production_centre = Centre.find_by_name!('WTSI')
        plan.save!

        plan2.production_centre = plan.production_centre
        assert_false plan2.valid?
        assert_match(/already has/, plan2.errors['gene'].first)
      end

      context '#is_active' do
        should 'exist' do
          assert_should have_db_column(:is_active).with_options(:null => false, :default => true)
        end

        should 'be true if an active micro-injection attempt found' do
          active_mi = Factory.create :mi_attempt2, :is_active => true
          active_mi.mi_plan.is_active = false
          active_mi.mi_plan.valid?
          assert_match(/cannot be set to false as active micro-injection attempt/, active_mi.mi_plan.errors[:is_active].first)
        end

        should 'cannot be set to false if an active phenotype attempt found' do
          gene = Factory.create :gene_cbx1
          plan = Factory.create :mi_plan_with_production_centre, :gene => gene, :is_active => true
          active_mi_attempt = Factory.create :mi_attempt2_status_gtc, :es_cell => Factory.create(:es_cell, :gene => gene), :mi_plan => plan
          active_pa = Factory.create :phenotype_attempt, :is_active => true, :mi_attempt => active_mi_attempt, :mi_plan => plan
          plan.reload
          plan.is_active = false
          assert_false plan.valid?
          assert_contains plan.errors[:is_active], /cannot be set to false as active phenotype attempt/
        end
      end
    end # attribute tests

    context '::with_mi_attempt' do
      should 'work' do
        10.times { Factory.create :mi_plan }
        10.times { Factory.create :mi_attempt2 }

        assert MiPlan.count > MiPlan.with_mi_attempt.count
        assert_equal 20, MiPlan.count
        assert_equal 10, MiPlan.with_mi_attempt.count
      end
    end

    context '::with_active_mi_attempt' do
      should 'work' do
        10.times { Factory.create :mi_plan }
        10.times { Factory.create :mi_attempt2, :is_active => true }
        10.times { Factory.create :mi_attempt2, :is_active => false }

        assert MiPlan.count > MiPlan.with_active_mi_attempt.count
        assert_equal 30, MiPlan.count
        assert_equal 10, MiPlan.with_active_mi_attempt.count
      end
    end

    context '::without_mi_attempt' do
      should 'work' do
        10.times { Factory.create :mi_plan }
        10.times { Factory.create :mi_attempt2 }

        assert MiPlan.count > MiPlan.without_mi_attempt.count
        assert_equal 20, MiPlan.count
        assert_equal 10, MiPlan.without_mi_attempt.count
      end
    end

    context '::without_active_mi_attempt' do
      should 'work' do
        10.times { Factory.create :mi_plan }
        10.times { Factory.create :mi_attempt2, :is_active => true }
        10.times { Factory.create :mi_attempt2, :is_active => false }

        assert MiPlan.count > MiPlan.without_active_mi_attempt.count
        assert_equal 30, MiPlan.count
        assert_equal 20, MiPlan.without_active_mi_attempt.count
      end
    end

    context '::with_genotype_confirmed_mouse' do
      should 'work' do
        10.times { Factory.create :mi_plan }
        10.times { Factory.create :mi_attempt2, :is_active => true }
        10.times do
          gene = Factory.create :gene
          mi = Factory.create :mi_attempt2_status_gtc,
                  :es_cell => Factory.create(:es_cell, :gene => gene),
                  :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', :gene => gene),
                  :is_active => true
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
        assert cbx1
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
        plan = Factory.create :mi_plan_with_production_centre
        assert plan.assigned?

        plan.update_attributes!(:number_of_es_cells_starting_qc => 1)
        assert plan.assigned?

        plan.update_attributes!(:number_of_es_cells_passing_qc => 1)
        assert plan.assigned?
      end

      should 'return false if status is not assigned' do
        plan = Factory.build :mi_plan_with_production_centre, :gene => cbx1
        plan.is_active = false; plan.valid?
        assert_false plan.assigned?

        Factory.create :mi_plan, :gene => cbx1

        plan.is_active = true; plan.valid?
        assert_equal 'Inspect - Conflict', plan.status.name
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
        mi_attempt = Factory.create :mi_attempt2_status_gtc,
                :es_cell => Factory.create(:es_cell, :gene => @gene),
                :mi_plan => TestDummy.mi_plan(@eucomm_cons.name, @ics_cent.name, @gene.marker_symbol, :force_assignment => true)

        mi_attempt = Factory.create :mi_attempt2_status_gtc,
                :es_cell => Factory.create(:es_cell, :gene => @gene),
                :mi_plan => TestDummy.mi_plan(@bash_cons.name, @jax_cent.name, @gene.marker_symbol, :force_assignment => true)

        mi_plan = Factory.create :mi_plan, :gene => @gene,
                :consortium => @mgp_cons, :production_centre => @cnb_cent

        assert_equal 'Inspect - GLT Mouse', mi_plan.status.name

        assert_equal "GLT mouse produced at: #{@ics_cent.name} (#{@eucomm_cons.name}), #{@jax_cent.name} (#{@bash_cons.name})",
                mi_plan.reason_for_inspect_or_conflict
      end

      should 'correctly return for Inspect - MI Attempt' do
        mi_attempt = Factory.create :mi_attempt2,
                :es_cell => Factory.create(:es_cell, :gene => @gene),
                :mi_plan => TestDummy.mi_plan(@eucomm_cons.name, @ics_cent.name, :gene => @gene, :force_assignment => true)

        mi_attempt = Factory.create :mi_attempt2,
                :es_cell => Factory.create(:es_cell, :gene => @gene),
                :mi_plan => TestDummy.mi_plan(@bash_cons.name, @jax_cent.name, :gene => @gene, :force_assignment => true),
                :is_active => true

        mi_plan = Factory.create :mi_plan, :gene => @gene,
                :consortium => @mgp_cons, :production_centre => @cnb_cent

        assert_equal 'Inspect - MI Attempt', mi_plan.status.name

        assert_match(/MI already in progress at:/, mi_plan.reason_for_inspect_or_conflict)
        assert_match(/#{@ics_cent.name} \(#{@eucomm_cons.name}\)/, mi_plan.reason_for_inspect_or_conflict)
        assert_match(/#{@jax_cent.name} \(#{@bash_cons.name}\)/, mi_plan.reason_for_inspect_or_conflict)
      end

      should 'correctly return for Inspect - Conflict' do
        Factory.create :mi_attempt2

        Factory.create :mi_plan, :gene => @gene,
                :consortium => @eucomm_cons, :production_centre => @ics_cent,
                :status => MiPlan::Status[:Assigned]

        Factory.create :mi_plan, :gene => @gene,
                :consortium => @bash_cons, :production_centre => @jax_cent,
                :number_of_es_cells_starting_qc => 5

        mi_plan = Factory.create :mi_plan, :gene => @gene,
                :consortium => @mgp_cons, :production_centre => @cnb_cent

        assert_equal 'Inspect - Conflict', mi_plan.status.name
        assert_match(/#{@bash_cons.name}/, mi_plan.reason_for_inspect_or_conflict)
        assert_match(/#{@eucomm_cons.name}/, mi_plan.reason_for_inspect_or_conflict)

      end

      should 'correctly return for Conflict' do
        Factory.create :mi_attempt2

        Factory.create :mi_plan, :gene => @gene,
                :consortium => @eucomm_cons, :production_centre => @ics_cent

        Factory.create :mi_plan, :gene => @gene,
                :consortium => @bash_cons, :production_centre => @jax_cent

        mi_plan = Factory.create :mi_plan, :gene => @gene,
                :consortium => @mgp_cons, :production_centre => @cnb_cent

        assert_equal 'Inspect - Conflict', mi_plan.status.name

        assert_equal "Other 'Assigned' MI plans for: #{@eucomm_cons.name}",
                mi_plan.reason_for_inspect_or_conflict
      end

      should 'return nil if no conflict' do
        mi_plan = Factory.create :mi_plan
        assert_nil mi_plan.reason_for_inspect_or_conflict
      end
    end

    context '#best_status_phenotype_attempt' do
      should 'return nil if there are no phenotype attempts for this MI' do
        assert_equal nil, default_mi_plan.best_status_phenotype_attempt
      end

      should 'return the best created active one if there are any active phenotype attempts' do
        default_mi_plan.production_centre = Centre.first
        mi_attempt = Factory.create :mi_attempt_genotype_confirmed, :es_cell => Factory.create(:es_cell, :gene => default_mi_plan.gene)
        Factory.create :phenotype_attempt, :mi_plan => default_mi_plan, :created_at => "2011-12-03 23:59:59 UTC", :mi_attempt => mi_attempt
        Factory.create :phenotype_attempt_status_cec, :mi_plan => default_mi_plan, :created_at => "2011-12-02 23:59:59 UTC", :mi_attempt => mi_attempt
        pt = Factory.create :phenotype_attempt_status_pdc, :mi_plan => default_mi_plan, :created_at => "2011-12-01 23:59:59 UTC", :mi_attempt => mi_attempt
        assert_equal pt, default_mi_plan.best_status_phenotype_attempt
      end
    end

    context '#latest_relevant_phenotype_attempt' do
      should 'return nil if there are no phenotype attempts for this MI' do
        assert_equal nil, default_mi_plan.latest_relevant_phenotype_attempt
      end

      should 'return the latest created active one if there are any active phenotype attempts' do
        mi_attempt = Factory.create :mi_attempt2_status_gtc,
                :es_cell => Factory.create(:es_cell, :gene => default_mi_plan.gene),
                :mi_plan => default_mi_plan
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
        mi_attempt = Factory.create :mi_attempt2_status_gtc,
                :es_cell => Factory.create(:es_cell, :gene => default_mi_plan.gene),
                :mi_plan => default_mi_plan
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
        assert cbx1

        mi_plan_args = {
          :mi_plan => bash_wtsi_cbx1_plan(:force_assignment => true),
          :es_cell => Factory.create(:es_cell, :gene => cbx1)
        }

        mi_attempt1 = Factory.create(:mi_attempt2_status_gtc, mi_plan_args)
        replace_status_stamps(mi_attempt1, [
          ['Genotype confirmed', '2011-05-13 05:04:01 UTC'],
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_attempt2 = Factory.create(:mi_attempt2_status_gtc, mi_plan_args)
        replace_status_stamps(mi_attempt2, [
          ['Genotype confirmed', '2011-05-13 05:04:01 UTC'],
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_plan_args[:es_cell] = Factory.create(:es_cell, :gene => cbx1)
        mi_attempt3 = Factory.create(:mi_attempt2_status_gtc, mi_plan_args)
        replace_status_stamps(mi_attempt3, [
          ['Genotype confirmed', '2011-05-13 05:04:01 UTC'],
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_plan_args[:es_cell] = Factory.create(:es_cell, :gene => cbx1)
        mi_attempt4 = Factory.create(:mi_attempt2, mi_plan_args)
        replace_status_stamps(mi_attempt4, [
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_plan_args[:es_cell] = Factory.create(:es_cell, :gene => cbx1)
        newer_mi_attempt = Factory.create(:mi_attempt2_status_gtc, mi_plan_args)

        mi_plan = mi_attempt1.mi_plan.reload
        result = mi_plan.distinct_old_genotype_confirmed_es_cells_count
        assert_equal 2, result
      end

      should 'not treat aborted MIs with a GC status stamp as GC' do
        assert cbx1

        mi_attempt = Factory.create(:mi_attempt2_status_gtc, :is_active => false)
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
        assert cbx1

        mi_plan_args = {
          :mi_plan => bash_wtsi_cbx1_plan(:force_assignment => true),
          :es_cell => Factory.create(:es_cell, :gene => cbx1)
        }

        mi_attempt1 = Factory.create(:mi_attempt2, mi_plan_args)
        replace_status_stamps(mi_attempt1, [
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_attempt2 = Factory.create(:mi_attempt2, mi_plan_args.merge(:is_active => false))
        replace_status_stamps(mi_attempt2, [
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC'],
          ['Micro-injection aborted', '2010-05-13 05:04:01 UTC'],
        ])

        mi_plan_args[:es_cell] = Factory.create(:es_cell, :gene => cbx1)
        mi_attempt3 = Factory.create(:mi_attempt2, mi_plan_args)
        replace_status_stamps(mi_attempt3, [
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_plan_args[:es_cell] = Factory.create(:es_cell, :gene => cbx1)
        mi_attempt4 = Factory.create(:mi_attempt2_status_gtc, mi_plan_args)
        replace_status_stamps(mi_attempt4, [
          ['Genotype confirmed', '2011-05-13 05:04:01 UTC'],
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_plan_args[:es_cell] = Factory.create(:es_cell, :gene => cbx1)
        newer_mi_attempt = Factory.create(:mi_attempt2, mi_plan_args)

        mi_plan = mi_attempt1.mi_plan.reload
        result = mi_attempt1.mi_plan.distinct_old_non_genotype_confirmed_es_cells_count
        assert_equal 2, result
      end

      should 'not treat aborted MIs with a GC status stamp as GC' do
        assert cbx1
        mi_plan_args = {
          :mi_plan => bash_wtsi_cbx1_plan(:force_assignment => true),
          :es_cell => Factory.create(:es_cell, :gene => cbx1)
        }

        mi_attempt = Factory.create(:mi_attempt2_status_gtc, :is_active => false)
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
          :consortium => Consortium.find_by_name!('MGP'))
        mi_plan.number_of_es_cells_passing_qc = 0
        mi_plan.save!

        results = mi_plan.latest_relevant_status

        assert_equal "Aborted - ES Cell QC Failed", results[:status]
        assert_equal Date.today.to_date, results[:date].to_date
      end

      should 'find attempt' do
        mi_attempt = Factory.create(:mi_attempt2, :is_active => false)

        results = mi_attempt.mi_plan.latest_relevant_status

        assert_equal "Micro-injection aborted", results[:status]
        assert_equal Date.today.to_date, results[:date].to_date
      end

      should 'find phenotype' do
        gene = Factory.create :gene_cbx1
        mi_plan = Factory.create :mi_plan_with_production_centre, :gene => gene
        mi_attempt = Factory.create :mi_attempt2_status_gtc,
                :es_cell => Factory.create(:es_cell, :gene => gene),
                :mi_plan => mi_plan
        phenotype = Factory.create :phenotype_attempt, :mi_plan => mi_plan,
          :mi_attempt => mi_attempt

        replace_status_stamps(phenotype,
          'Phenotype Attempt Registered' => '2011-10-30')

        results = mi_plan.latest_relevant_status

        assert_equal "Phenotype Attempt Registered", results[:status]
        assert_equal '2011-10-30', results[:date]
      end

    end

    context '#relevant_status_stamp' do

      should 'find plan' do
        gene = Factory.create :gene_cbx1
        mi_plan = Factory.create(:mi_plan, :gene => gene,
          :consortium => Consortium.find_by_name!('MGP'),
          :number_of_es_cells_passing_qc => 0)

        results = mi_plan.relevant_status_stamp

        assert_equal "aborted_es_cell_qc_failed", results[:status]
        assert_equal Date.today.to_date, results[:date].to_date
      end

      should 'find attempt' do
        mi_attempt = Factory.create(:mi_attempt2, :is_active => false)

        results = mi_attempt.mi_plan.relevant_status_stamp

        assert_equal "microinjection_aborted", results[:status]
        assert_equal Date.today.to_date, results[:date].to_date
      end

      should 'find phenotype with earliest date stamp' do
        gene = Factory.create :gene_cbx1
        mi_plan = Factory.create :mi_plan_with_production_centre, :gene => gene
        mi_attempt = Factory.create :mi_attempt2_status_gtc,
                :mi_plan => mi_plan,
                :es_cell => Factory.create(:es_cell, :gene => gene)
        phenotype = Factory.create :phenotype_attempt, :mi_plan => mi_plan,
                :created_at => "2011-12-02",
                :mi_attempt => mi_attempt

        replace_status_stamps(phenotype,
        'Phenotype Attempt Registered' => '2011-10-30')

        results = mi_plan.relevant_status_stamp

        assert_equal "phenotype_attempt_registered", results[:status]
        assert_equal Date.parse('2011-10-30').to_date, results[:date].to_date
      end

    end


    context '#total_pipeline_efficiency_gene_count' do
      should 'NOT find one with incorrect date' do
        d = DateTime.now.to_date

        mi_attempt1 = Factory.create(:mi_attempt2)
        replace_status_stamps(mi_attempt1, [
          ['Micro-injection in progress', "#{d.year}-#{d.month}-13 05:04:01 UTC"]
        ])

        mi_plan = mi_attempt1.mi_plan.reload
        result = mi_attempt1.mi_plan.total_pipeline_efficiency_gene_count
        assert_equal 0, result
      end

      should 'NOT find one with wrong status' do
        d = DateTime.now.to_date

        mi_attempt1 = Factory.create(:mi_attempt2)
        replace_status_stamps(mi_attempt1, [
          ['Micro-injection aborted', "#{d.year}-#{d.month}-13 05:04:01 UTC"]
        ])

        mi_plan = mi_attempt1.mi_plan.reload
        result = mi_attempt1.mi_plan.total_pipeline_efficiency_gene_count
        assert_equal 0, result
      end

      should 'find one beyond six months old' do
        mi_attempt1 = Factory.create(:mi_attempt2)
        replace_status_stamps(mi_attempt1, [
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_plan = mi_attempt1.mi_plan.reload
        result = mi_attempt1.mi_plan.total_pipeline_efficiency_gene_count
        assert_equal 1, result
      end
    end

    context '#total_pipeline_efficiency_gene_count' do
      should 'NOT find one with incorrect date' do
        d = DateTime.now.to_date

        mi_attempt1 = Factory.create(:mi_attempt2)
        replace_status_stamps(mi_attempt1, [
          ['Micro-injection in progress', "#{d.year}-#{d.month}-13 05:04:01 UTC"]
        ])

        mi_plan = mi_attempt1.mi_plan.reload
        result = mi_attempt1.mi_plan.total_pipeline_efficiency_gene_count
        assert_equal 0, result
      end

      should 'NOT find one with wrong status' do
        d = DateTime.now.to_date

        mi_attempt1 = Factory.create(:mi_attempt2, :is_active => false)
        replace_status_stamps(mi_attempt1, [
          ['Micro-injection aborted', "#{d.year}-#{d.month}-13 05:04:01 UTC"]
        ])

        mi_plan = mi_attempt1.mi_plan.reload
        result = mi_attempt1.mi_plan.total_pipeline_efficiency_gene_count
        assert_equal 0, result
      end

      should 'find one beyond six months old' do
        mi_attempt1 = Factory.create(:mi_attempt2)
        replace_status_stamps(mi_attempt1, [
          ['Micro-injection in progress', '2010-05-13 05:04:01 UTC']
        ])

        mi_plan = mi_attempt1.mi_plan.reload
        result = mi_attempt1.mi_plan.total_pipeline_efficiency_gene_count
        assert_equal 1, result
      end
    end

    should 'include HasStatuses' do
      assert_include default_mi_plan.class.ancestors, ApplicationModel::HasStatuses
    end

    should 'have ::readable_name' do
      assert_equal 'plan', MiPlan.readable_name
    end

  end
end
