# encoding: utf-8

require 'test_helper'

class Public::MiPlanTest < ActiveSupport::TestCase
  context 'Public::MiPlan' do

    def default_mi_plan
      @default_mi_plan ||= Factory.create(:mi_plan).to_public
    end

    context 'audits' do
      should ', on create, still be created for MiPlan, not this public version' do
        Factory.create :gene_cbx1
        plan = Public::MiPlan.create!(:priority_name => 'Low', :marker_symbol => 'Cbx1',
          :consortium_name => 'JAX')
        assert_equal 'MiPlan', plan.audits.last.auditable_type
      end

      should ', on update, still be created for MiPlan, not this public version' do
        default_mi_plan.update_attributes!(:number_of_es_cells_starting_qc => 6)
        assert_equal 'MiPlan', default_mi_plan.audits.last.auditable_type
      end
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

    context '#number_of_es_cells_starting_qc' do
      should 'validate non-blankness only it was previously set to a number' do
        assert_equal nil, default_mi_plan.number_of_es_cells_starting_qc
        default_mi_plan.number_of_es_cells_starting_qc = 5
        default_mi_plan.save!

        default_mi_plan.number_of_es_cells_starting_qc = nil
        assert_false default_mi_plan.save

        assert ! default_mi_plan.errors[:number_of_es_cells_starting_qc].blank?
      end
    end

    context '#number_of_es_cells_passing_qc' do
      should 'validate non-blankness only it was previously set to a number' do
        assert_equal nil, default_mi_plan.number_of_es_cells_passing_qc
        default_mi_plan.number_of_es_cells_passing_qc = 5
        default_mi_plan.save!

        default_mi_plan.number_of_es_cells_passing_qc = nil
        assert_false default_mi_plan.save

        assert ! default_mi_plan.errors[:number_of_es_cells_passing_qc].blank?
      end

      should 'validate cannot be set to 0 if was previously non-zero' do
        2.times do |i|
          default_mi_plan.number_of_es_cells_passing_qc = 0
          default_mi_plan.save!
        end

        default_mi_plan.number_of_es_cells_passing_qc = 5
        default_mi_plan.save!

        default_mi_plan.number_of_es_cells_passing_qc = nil
        assert_false default_mi_plan.save
        assert ! default_mi_plan.errors[:number_of_es_cells_passing_qc].blank?

        default_mi_plan.number_of_es_cells_passing_qc = 0
        assert_false default_mi_plan.save
        assert ! default_mi_plan.errors[:number_of_es_cells_passing_qc].blank?
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
        'sub_project_name',
        'is_active'
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
        'sub_project_name',
        'is_active',
        'status_dates',
        'mgi_accession_id'
      ]
      got = default_mi_plan.as_json.keys
      assert_equal expected.sort, got.sort
    end

    context '#as_json' do
      should 'take nil as param' do
        assert_nothing_raised { default_mi_plan.as_json(nil) }
      end
    end

    context '::translate_public_param' do
      should 'translate marker_symbol for search' do
        assert_equal 'gene_marker_symbol_eq',
                Public::MiPlan.translate_public_param('marker_symbol_eq')
      end

      should 'translate mgi_accession_id for search' do
        assert_equal 'gene_mgi_accession_id_in',
                Public::MiPlan.translate_public_param('mgi_accession_id_in')
      end

      should 'translate marker_symbol for sort' do
        assert_equal 'gene_marker_symbol desc',
                Public::MiPlan.translate_public_param('marker_symbol desc')
        assert_equal 'gene_marker_symbol asc',
                Public::MiPlan.translate_public_param('marker_symbol asc')
      end

      should 'leave other params untouched' do
        assert_equal 'consortium_name_not_in',
                Public::MiPlan.translate_public_param('consortium_name_not_in')
        assert_equal 'production_centre_name asc',
                Public::MiPlan.translate_public_param('production_centre_name asc')
      end
    end

    context '::public_search' do
      should 'not need to pass "sorts" parameter' do
        assert Public::MiPlan.public_search(:consortium_name_eq => default_mi_plan.consortium.name, :sorts => nil).result
      end

      should 'pass on parameters not needing translation to ::search' do
        assert_equal default_mi_plan.id,
                Public::MiPlan.public_search(:consortium_name_eq => default_mi_plan.consortium.name).result.first.id
      end

      should 'translate searching predicates' do
        plan = Factory.create(:mi_plan, :gene => Factory.create(:gene_cbx1)).to_public
        result = Public::MiPlan.public_search(:marker_symbol_eq => 'Cbx1').result
        assert_equal [plan], result
      end

      should 'translate sorting predicates' do
        Factory.create :mi_plan, :gene => Factory.create(:gene, :marker_symbol => 'Def1')
        Factory.create :mi_plan, :gene => Factory.create(:gene, :marker_symbol => 'Xyz3')
        Factory.create :mi_plan, :gene => Factory.create(:gene, :marker_symbol => 'Abc2')

        result = Public::MiPlan.public_search(:sorts => 'marker_symbol desc').result
        assert_equal ['Xyz3', 'Def1', 'Abc2'], result.map(&:marker_symbol)
      end
    end

    context '#status_dates' do
      should 'show status stamps and their dates' do
        plan = Factory.create :mi_plan_with_production_centre
        mi = Factory.create :mi_attempt, :consortium_name => plan.consortium.name,
                :production_centre_name => plan.production_centre.name,
                :es_cell => Factory.create(:es_cell, :gene => plan.gene)
        assert_equal plan, mi.mi_plan

        plan = mi.mi_plan
        plan.number_of_es_cells_starting_qc = 4
        plan.save!

        status_dates = {
          'Interest' => '2011-01-01',
          'Assigned' => '2011-02-01',
          'Assigned - ES Cell QC In Progress' => '2011-03-01'
        }
        replace_status_stamps(plan, status_dates)

        plan = plan.to_public
        assert_equal status_dates, plan.status_dates
      end
    end

    context '#mgi_accession_id' do
      should 'return gene mgi_accession_id' do
        plan = Factory.create(:mi_plan).to_public
        assert_equal plan.gene.mgi_accession_id, plan.mgi_accession_id
      end
    end

  end
end
