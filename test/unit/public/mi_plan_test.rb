# encoding: utf-8

require 'test_helper'

class Public::MiPlanTest < ActiveSupport::TestCase
  context 'Public::MiPlan' do

    def default_mi_plan
      if ! @default_mi_plan
        mi_plan = Factory.create :mi_plan
        @default_mi_plan = Public::MiPlan.find(mi_plan.id)
      end
      return @default_mi_plan
    end

    context 'audits' do
      should ', on create, still be created for MiPlan, not this public version'

      should ', on update, still be created for MiPlan, not this public version'
    end

    context '#sub_project_name' do
      should 'be accessible via the name attribute' do
        sp = MiPlan::SubProject.create!(:name => 'Nonexistent')
        default_mi_plan.sub_project_name = 'Nonexistent'
        default_mi_plan.valid?
        assert_equal sp, default_mi_plan.sub_project
      end
    end

    context '#marker_symbol' do
      should 'use AccessAssociationByAttribute' do
        gene = Factory.create :gene_cbx1
        assert_not_equal 'Cbx1', default_mi_plan.gene.marker_symbol
        default_mi_plan.marker_symbol = 'Cbx1'
        assert_equal gene, default_mi_plan.gene
      end

      should 'be present' do
        assert_should validate_presence_of :marker_symbol
      end

      should 'not be updateable' do
        gene = Factory.create :gene_cbx1
        assert_not_equal gene, default_mi_plan.gene
        default_mi_plan.marker_symbol = 'Cbx1'
        default_mi_plan.valid?
        assert_match /cannot be changed/, default_mi_plan.errors[:marker_symbol].first
      end
    end

    context '#consortium_name' do
      should 'use AccessAssociationByAttribute' do
        consortium = Factory.create :consortium
        default_mi_plan.consortium_name = consortium.name
        assert_equal consortium, default_mi_plan.consortium
      end

      should 'be present' do
        assert_should validate_presence_of :consortium_name
      end

      should 'not be updateable' do
        assert_not_equal 'MGP', default_mi_plan.consortium_name
        default_mi_plan.consortium_name = 'MGP'
        default_mi_plan.valid?
        assert_match /cannot be changed/, default_mi_plan.errors[:consortium_name].first
      end
    end

    context '#production_centre_name' do
      def centre
        @centre ||= Factory.create(:centre)
      end

      should 'use AccessAssociationByAttribute' do
        default_mi_plan.production_centre_name = centre.name
        assert_equal centre, default_mi_plan.production_centre
      end

      should 'not allow setting back to nil once assigned to something' do
        mi_plan = Public::MiPlan.find(Factory.create(:mi_plan, :production_centre => nil).id)
        mi_plan.production_centre_name = centre.name
        assert mi_plan.save
        mi_plan.production_centre_name = nil
        assert ! mi_plan.valid?
        assert_include mi_plan.errors[:production_centre_name], 'cannot be blank'
      end

      should 'can be set to nil on create and can stay that way on update' do
        assert_equal nil, default_mi_plan.production_centre_name
        assert default_mi_plan.save
        assert default_mi_plan.save
        assert default_mi_plan.valid?, default_mi_plan.errors.inspect
      end

      should 'not be updateable if the MiPlan has any MiAttempts' do
        mi = Factory.create :mi_attempt, :production_centre_name => 'WTSI'
        plan = Public::MiPlan.find(mi.mi_plan.id)
        plan.production_centre_name = 'ICS'
        plan.valid?
        assert_match /cannot be changed/, plan.errors[:production_centre_name].first
      end
    end

    context '#priority_name' do
      should 'use AccessAssociationByAttribute' do
        priority = MiPlan::Priority.find_by_name!('Medium')
        assert_not_equal priority.name,  default_mi_plan.priority.name
        default_mi_plan.priority_name = 'Medium'
        assert_equal priority, default_mi_plan.priority
      end

      should 'be present' do
        assert_should validate_presence_of :priority_name
      end
    end

    context '#status_name' do
      should 'use AccessAssociationByAttribute' do
        status = MiPlan::Status[:Conflict]
        assert_not_equal status.name, default_mi_plan.status_name
        default_mi_plan.status_name = 'Conflict'
        assert_equal status, default_mi_plan.status
      end
    end

    should 'limit the public mass-assignment API' do
      expected = [
        'marker_symbol',
        'consortium_name',
        'production_centre_name',
        'priority_name',
        'number_of_es_cells_starting_qc',
        'number_of_es_cells_passing_qc',
        'withdrawn',
        'sub_project_name'
      ]
      got = (Public::MiPlan.accessible_attributes.to_a - ['audit_comment'])
      assert_equal expected.sort, got.sort
    end

    should 'have defined attributes in JSON output' do
      expected = [
        'id',
        'marker_symbol',
        'consortium_name',
        'production_centre_name',
        'priority_name',
        'status_name',
        'number_of_es_cells_starting_qc',
        'number_of_es_cells_passing_qc',
        'withdrawn',
        'sub_project_name'
      ]
      got = default_mi_plan.as_json.keys
      assert_equal expected.sort, got.sort
    end

    context '#as_json' do
      should 'take nil as param' do
        assert_nothing_raised { @default_mi_plan.as_json(nil) }
      end
    end

  end
end
