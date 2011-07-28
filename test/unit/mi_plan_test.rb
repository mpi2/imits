# encoding: utf-8

require 'test_helper'

class MiPlanTest < ActiveSupport::TestCase
  context 'MiPlan' do

    setup do
      Factory.create :mi_plan
    end

    should belong_to :gene
    should belong_to :consortium
    should belong_to :production_centre
    should belong_to :mi_plan_status
    should belong_to :mi_plan_priority

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

    context '::assign_genes_and_mark_conflicts' do
      should 'set Interested MiPlan to Assigned status if no other Interested or Assigned MiPlan for the same gene exists' do
        gene = Factory.create :gene_cbx1
        only_interest_mi_plan = Factory.create :mi_plan, :gene => gene, :consortium => Consortium.find_by_name!('BASH')

        MiPlan.assign_genes_and_mark_conflicts

        only_interest_mi_plan.reload
        assert_equal 'Assigned', only_interest_mi_plan.mi_plan_status.name
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
      end

      should 'set Interested MiPlan to Assigned if only Declined MiPlans exist for that gene'
    end

  end
end
