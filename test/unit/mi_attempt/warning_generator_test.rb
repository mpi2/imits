# encoding: utf-8

require 'test_helper'

class MiAttempt::WarningGeneratorTest < ActiveSupport::TestCase
  context 'MiAttempt::WarningGenerator' do

    should 'not generate warnings when there are none' do
      Factory.create :mi_attempt
      mi = Factory.build :mi_attempt
      Factory.create(:mi_plan, mi.mi_plan_lookup_conditions.merge(:mi_plan_status => MiPlanStatus[:Assigned]))

      assert_false mi.generate_warnings
      assert_equal nil, mi.warnings
    end

    context 'when trying to create MI for already injected gene' do
      setup do
        es_cell = Factory.create :es_cell_EPD0029_1_G04
        @existing_mi = es_cell.mi_attempts.first
        @mi = Factory.build :mi_attempt,
                :es_cell => Factory.create(:es_cell, :gene => @existing_mi.es_cell.gene)
      end

      should 'generate warning for new record' do
        assert_true @mi.generate_warnings
        assert_include @mi.warnings, MiAttempt::WARNING_MESSAGES[:gene_already_micro_injected]
      end

      should 'not generate warning for existing record' do
        @mi.save!
        assert_false @mi.generate_warnings
      end
    end

    should 'generate warning if MiPlan that will be assigned does not have status already set to Assigned' do
      gene = Factory.create :gene_cbx1
      Factory.create :mi_plan, :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :gene => gene, :mi_plan_status => MiPlanStatus[:Interest]
      es_cell = Factory.create :es_cell, :gene => gene

      mi = Factory.build :mi_attempt, :consortium_name => 'BaSH',
              :production_centre_name => 'WTSI',
              :es_cell => es_cell

      assert_true mi.generate_warnings
      assert_equal 1, mi.warnings.size
      assert_match 'has not been assigned to WTSI', mi.warnings.first
    end

    should 'generate warning if MiPlan for the MiAttempt has to be created' do
      mi = Factory.build :mi_attempt, :production_centre_name => 'ICS'
      assert_equal 0, MiPlan.count

      assert_true mi.generate_warnings
      assert_match 'has not been assigned to ICS', mi.warnings.join
    end

    should 'be able to generate more than one warning' do
      es_cell = Factory.create :es_cell_EPD0029_1_G04
      existing_mi = es_cell.mi_attempts.first
      mi = Factory.build :mi_attempt,
              :es_cell => Factory.create(:es_cell, :gene => existing_mi.es_cell.gene)
      assert_true mi.generate_warnings
      assert_equal 2, mi.warnings.size
    end

    should 'raise if trying to generate warnings while there are validation errors' do
      mi = Factory.build :mi_attempt
      mi.consortium_name = nil
      assert_false mi.valid?

      assert_raise_message(/non-valid/) do
        mi.generate_warnings
      end
    end

  end
end
