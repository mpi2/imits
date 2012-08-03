# encoding: utf-8

require 'test_helper'

class MiPlan::StatusChangerTest < ActiveSupport::TestCase
  context 'MiPlan::StatusChanger' do

    context 'for attribute-based statuses' do
      def default_mi_plan
        @default_mi_plan ||= Factory.create :mi_plan, :gene => cbx1
      end

      should 'set status to Assigned by default' do
        assert_equal 'Assigned', default_mi_plan.status.name
      end

      should 'set status to "Assigned - ES Cells QC In Progress" if number_of_es_cells_starting_qc is set to not null and passing_qc is null' do
        assert_equal 'Assigned', default_mi_plan.status.name

        default_mi_plan.number_of_es_cells_starting_qc = 0
        default_mi_plan.valid?
        assert_equal 'Assigned - ES Cell QC In Progress', default_mi_plan.status.name
      end

      should 'set status to "Assigned - ES Cells QC Complete" if number_of_es_cells_passing_qc is set to > 0' do
        assert_equal 'Assigned', default_mi_plan.status.name

        default_mi_plan.number_of_es_cells_starting_qc = 10
        default_mi_plan.number_of_es_cells_passing_qc = nil
        default_mi_plan.valid?
        assert_equal 'Assigned - ES Cell QC In Progress', default_mi_plan.status.name

        default_mi_plan.number_of_es_cells_passing_qc = 6
        default_mi_plan.valid?
        assert_equal 'Assigned - ES Cell QC Complete', default_mi_plan.status.name
      end

      should 'set status to "Aborted - ES Cell QC Failed" if number_of_es_cells_passing_qc is set to 0' do
        assert_equal 'Assigned', default_mi_plan.status.name

        default_mi_plan.number_of_es_cells_starting_qc = 5
        default_mi_plan.number_of_es_cells_passing_qc = 0
        default_mi_plan.valid?
        assert_equal 'Aborted - ES Cell QC Failed', default_mi_plan.status.name
      end

      should 'not do any status changes if it is currently Inactive' do
        default_mi_plan.update_attributes!(:is_active => false)
        assert_equal 'Inactive', default_mi_plan.status.name

        default_mi_plan.number_of_es_cells_passing_qc = 6
        default_mi_plan.valid?
        assert_equal 'Inactive', default_mi_plan.status.name
      end

      should 'set "Inactive" status when is_active is set to false ahead of other statuses' do
        default_mi_plan.update_attributes!(:is_active => false, :number_of_es_cells_starting_qc => 5)
        default_mi_plan.valid?
        assert_equal 'Inactive', default_mi_plan.status.name
      end

      should 'set "Withdrawn" status when #withdrawn is set to true' do
        ins_con = MiPlan::Status['Inspect - Conflict']
        same_gene_plan = TestDummy.mi_plan default_mi_plan.marker_symbol
        if same_gene_plan.status.name != ins_con.name
          MiPlan.connection.execute("update mi_plans set status_id = #{ins_con.id} where mi_plans.id = #{same_gene_plan.id};")
          same_gene_plan.reload
        end

        same_gene_plan.withdrawn = true
        assert same_gene_plan.valid?, same_gene_plan.errors.full_messages.join
        assert_equal true, same_gene_plan.withdrawn?
        assert_equal 'Withdrawn', same_gene_plan.status.name
      end
    end

    def create_another_assigned_plan
      assert_equal 'Assigned', default_mi_plan.status.name
      return TestDummy.mi_plan default_mi_plan.marker_symbol, :force_assignment => true
    end

    context 'for pre-assignment statuses when a new record' do
      should 'set status to "Inspect - Conflict" if only other plans for gene are Assigned or pre-assignment' do
        assert_equal 'Assigned', default_mi_plan.status.name
        same_gene_plan = TestDummy.mi_plan default_mi_plan.marker_symbol
        assert_equal 'Inspect - Conflict', same_gene_plan.status.name
      end

      should 'set status to "Inspect - MI Attempt" if only other plans for gene are Assigned or pre-assignment and there are MIs as far as "in progress" for the gene' do
        Factory.create :mi_attempt, :es_cell => Factory.create(:es_cell, :gene => default_mi_plan.gene)
        same_gene_plan = TestDummy.mi_plan default_mi_plan.marker_symbol
        assert_equal 'Inspect - MI Attempt', same_gene_plan.status.name
      end

      should 'NOT set "Inspect - MI Attempt" by counting aborted MI as in progress' do
        mi = Factory.create :mi_attempt, :es_cell => Factory.create(:es_cell, :gene => cbx1), :is_active => false
        mi.mi_plan.update_attributes!(:is_active => false)
        same_gene_plan = TestDummy.mi_plan cbx1.marker_symbol
        assert_equal 'Assigned', same_gene_plan.status.name
      end

      should 'set status to "Inspect - GLT Mouse" if only other plans for the gene are Assigned or pre-assignment and there are MIs as far as "genotype confirmed" for the gene' do
        Factory.create :mi_attempt_genotype_confirmed, :es_cell => Factory.create(:es_cell, :gene => default_mi_plan.gene)
        same_gene_plan = TestDummy.mi_plan default_mi_plan.marker_symbol
        assert_equal 'Inspect - GLT Mouse', same_gene_plan.status.name
      end
    end

    context 'when affecting statuses of OTHER plans' do
      should ', if an Assigned plan is inactivated for a gene and several plans remain, they should go from "Inspect - Conflict" to "Conflict"' do
        assert_equal 'Assigned', default_mi_plan.status.name
        other1 = TestDummy.mi_plan default_mi_plan.marker_symbol
        other2 = TestDummy.mi_plan default_mi_plan.marker_symbol
        assert_equal 'Inspect - Conflict', other1.status.name
        assert_equal 'Inspect - Conflict', other2.status.name

        default_mi_plan.is_active = false; default_mi_plan.save!
        other1.reload; assert_equal 'Conflict', other1.status.name
        other2.reload; assert_equal 'Conflict', other2.status.name
      end

      should ', if an Assigned plan is inactivated for a gene, and only 1 plan remains, it should go from "Inspect - Conflict" to "Assigned"' do
        assert_equal 'Assigned', default_mi_plan.status.name
        other = TestDummy.mi_plan default_mi_plan.marker_symbol
        assert_equal 'Inspect - Conflict', other.status.name
        default_mi_plan.is_active = false; default_mi_plan.save!
        other.reload; assert_equal 'Assigned', other.status.name
      end

      should ', if an Assigned plan is deleted for for a gene, and only 1 plan remains, it should go from "Inspect - Conflict" to "Assigned"' do
        assert_equal 'Assigned', default_mi_plan.status.name
        other = TestDummy.mi_plan default_mi_plan.marker_symbol
        assert_equal 'Inspect - Conflict', other.status.name
        default_mi_plan.destroy
        other.reload; assert_equal 'Assigned', other.status.name
      end
    end

    should 'NOT set a pre-assignment status if conditions are met but the force_assignment virtual attribute is passed through' do
      same_gene_plan = TestDummy.mi_plan default_mi_plan.marker_symbol
      assert_equal 'Inspect - Conflict', same_gene_plan.status.name
      same_gene_plan.save!
      assert_equal 'Inspect - Conflict', same_gene_plan.status.name
      same_gene_plan.update_attributes!(:force_assignment => true)
      assert_equal 'Assigned', same_gene_plan.status.name
    end

    should 'NOT set a pre-assignment status from a post-assignment status if it is NOT a new record even though conditions are met' do
      assigned_plan = create_another_assigned_plan
      assigned_plan.force_assignment = false
      assigned_plan.save!
      assert_equal 'Assigned', assigned_plan.status.name
    end

  end
end
