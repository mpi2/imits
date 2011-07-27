# encoding: utf-8

require 'test_helper'

class MiPlanTest < ActiveSupport::TestCase
  context 'MiPlan' do
    setup do
      Factory.create :mi_plan
    end

    should belong_to :gene
    should belong_to :consortium
    should belong_to :mi_plan_status
    should belong_to :mi_plan_priority

    should validate_presence_of :gene
    should validate_presence_of :consortium
    should validate_presence_of :mi_plan_status
    should validate_presence_of :mi_plan_priority

    should 'validate the uniqueness of gene_id scoped to consortium_id' do
      mip = MiPlan.first
      mip_dup = MiPlan.new( :gene => mip.gene, :consortium => mip.consortium )
      assert_false mip_dup.save
      assert_false mip_dup.valid?
    end
  end
end
