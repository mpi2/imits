# encoding: utf-8

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

      should 'validate the uniqueness of gene_id scoped to consortium_id and production_centre_id' do
        mip = Factory.build :mi_plan
        assert mip.save
        assert mip.valid?

        mip2 = MiPlan.new( :gene => mip.gene, :consortium => mip.consortium )
        assert_false mip2.save
        assert_false mip2.valid?
        assert ! mip2.errors['gene_id'].blank?

        mip.production_centre = Centre.find_by_name('WTSI')
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

    context '#consortium' do
      should_eventually 'not output ids in serialization' do
        data = MiPlan.first.as_json
        assert_false data.keys.include?('consortium_id')
      end

      should 'allow access to the consortium via its name' do
        Factory.create :consortium, :name => 'WEEEEEE'
        @default_mi_plan.update_attributes( :consortium_name => 'WEEEEEE' )
        assert_equal 'WEEEEEE', @default_mi_plan.consortium.name
      end
    end

    context '#production_centre' do
      should 'allow access to production centre via its name' do
        Factory.create :centre, :name => 'NONEXISTENT'
        @default_mi_plan.update_attributes(:production_centre_name => 'NONEXISTENT')
        assert_equal 'NONEXISTENT', @default_mi_plan.production_centre.name
      end
    end

    context '::assign_genes_and_mark_conflicts' do
      def setup_for_set_one_to_assigned
        gene = Factory.create :gene_cbx1
        @only_interest_mi_plan = Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!('BASH')
        @declined_mi_plans = [
          Factory.create(:mi_plan, :gene => gene,
            :consortium => Consortium.find_by_name!('MGP'),
            :mi_plan_status => MiPlanStatus.find_by_name!('Declined')),
          Factory.create(:mi_plan, :gene => gene,
            :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'),
            :mi_plan_status => MiPlanStatus.find_by_name!('Declined'))
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
        assert_equal ['Declined', 'Declined'], @declined_mi_plans.map{|i| i.mi_plan_status.name}
        MiPlan.assign_genes_and_mark_conflicts
      end

      should 'set all Interested MiPlans that have the same gene to Conflict' do
        gene = Factory.create :gene_cbx1
        mi_plans = ['BASH', 'MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!(consortium_name)
        end

        MiPlan.assign_genes_and_mark_conflicts

        mi_plans.each(&:reload)
        assert_equal ['Conflict', 'Conflict', 'Conflict'],
                mi_plans.map {|i| i.mi_plan_status.name }

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
                :gene => gene, :consortium => Consortium.find_by_name!('BASH')

        MiPlan.assign_genes_and_mark_conflicts
        interested_mi_plan.reload

        assert_equal 'Conflict', interested_mi_plan.mi_plan_status.name

        MiPlan.assign_genes_and_mark_conflicts
      end

      should 'set all Interested MiPlans to Declined if other MiPlans for the same gene are already Assigned' do
        gene = Factory.create :gene_cbx1
        Factory.create :mi_plan, :gene => gene,
                :consortium => Consortium.find_by_name!('BASH'),
                :mi_plan_status => MiPlanStatus.find_by_name!('Assigned')
        mi_plans = ['MGP', 'EUCOMM-EUMODIC'].map do |consortium_name|
          Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!(consortium_name)
        end

        MiPlan.assign_genes_and_mark_conflicts
        mi_plans.each(&:reload)

        assert_equal ['Declined', 'Declined'],
                mi_plans.map {|i| i.mi_plan_status.name }

        MiPlan.assign_genes_and_mark_conflicts
      end

    end # ::assign_genes_and_mark_conflicts

    context '::all_grouped_by_mgi_accession_id_then_by_status_name' do
      should 'work' do
        Factory.create :consortium, :name => 'Consortium X'
        gene1 = Factory.create :gene_cbx1
        gene2 = Factory.create :gene_trafd1
        bash = Factory.create :mi_plan, :gene => gene1,
                :consortium => Consortium.find_by_name!('BASH'),
                :mi_plan_status => MiPlanStatus.find_by_name!('Interest')
        consortium_x = Factory.create :mi_plan, :gene => gene1,
                :consortium => Consortium.find_by_name!('Consortium X'),
                :mi_plan_status => MiPlanStatus.find_by_name!('Interest')
        mgp = Factory.create :mi_plan, :gene => gene1,
                :consortium => Consortium.find_by_name!('MGP'),
                :mi_plan_status => MiPlanStatus.find_by_name!('Assigned')
        eucomm = Factory.create :mi_plan, :gene => gene2,
                :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'),
                :mi_plan_status => MiPlanStatus.find_by_name!('Declined')

        result = MiPlan.all_grouped_by_mgi_accession_id_then_by_status_name

        assert_equal [bash, consortium_x].sort, result[gene1.mgi_accession_id]['Interest'].sort
        assert_equal [mgp], result[gene1.mgi_accession_id]['Assigned']
        assert_equal [eucomm], result[gene2.mgi_accession_id]['Declined']
      end
    end

  end
end
