  # encoding: utf-8

require 'test_helper'

class MiAttempt::WarningGeneratorTest < ActiveSupport::TestCase
  context 'MiAttempt::WarningGenerator' do

    should 'not generate warnings when there are none' do
      Factory.create :mi_attempt2,
              :mi_plan => TestDummy.mi_plan('MGP', 'MARC')
      gene = Factory.create :gene_cbx1
      allele = Factory.create :allele, :gene => gene

      mi_plan = Factory.create(:mi_plan,
        :gene => gene,
        :consortium => Consortium.find_by_name!('BaSH'),
        :production_centre => Centre.find_by_name!('WTSI'),
        :force_assignment => true)

      mi = Factory.build(:public_mi_attempt,
        :es_cell_name => Factory.create(:es_cell, :allele => allele).name,
        :mi_plan => mi_plan)

      assert_false mi.generate_warnings, mi.warnings
      assert_equal nil, mi.warnings
    end

    context 'when trying to create MI for already injected gene' do
      setup do
        es_cell = Factory.create :es_cell_EPD0029_1_G04, :allele => Factory.create(:allele_with_gene_gatc)
        allele = TargRep::TargetedAllele.includes(:gene).where("genes.marker_symbol = 'Gatc'").first or raise ActiveRecord::RecordNotFound
        @existing_mi = es_cell.mi_attempts.first
        @mi = Factory.build(:public_mi_attempt,
          :es_cell => Factory.create(:es_cell, :allele => allele),
          :mi_plan => @existing_mi.mi_plan)
      end

      should 'generate warning for new record' do
        assert @mi.valid?, @mi.errors.inspect
        assert_true @mi.generate_warnings
        assert_equal 1, @mi.warnings.size
        assert_match 'already been micro-injected', @mi.warnings.first
      end

      should 'not generate warning for existing record' do
        @mi.save!
        assert_false @mi.generate_warnings
      end
    end

    should 'not generate warning if MiPlan that will be assigned already has an assigned status' do
      gene = Factory.create :gene_cbx1
      allele = Factory.create :allele, :gene => gene
      mi_plan = Factory.create :mi_plan, :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :gene => gene, :force_assignment => true
      es_cell = Factory.create :es_cell, :allele => allele

      mi = Factory.build :public_mi_attempt,
              :mi_plan => mi_plan,
              :es_cell_name => es_cell.name
      assert_false mi.generate_warnings, mi.warnings.inspect

      mi_plan.save!

      mi = Factory.build :public_mi_attempt,
              :mi_plan => mi_plan,
              :es_cell_name => es_cell.name
      assert mi.valid?
      assert_false mi.generate_warnings, mi.warnings
    end

    context 'when checking if MiPlan to be assigned has a production centre' do
      should 'generate warning if it does not have production centre' do
        gene = Factory.create :gene_cbx1
        allele = Factory.create :allele, :gene => gene
        mi_plan = Factory.create :mi_plan, :consortium => Consortium.find_by_name!('BaSH'),
                :production_centre => nil,
                :gene => gene, :force_assignment => true
        es_cell = Factory.create :es_cell, :allele => allele

        mi = Factory.build :public_mi_attempt, :mi_plan => mi_plan,
                :es_cell_name => es_cell.name
        assert mi.valid?

        assert_true mi.generate_warnings
        expected_message = 'Continuing will assign your production centre as the production centre micro-injecting the gene on behalf of BaSH'
        assert_match expected_message, mi.warnings.first
        assert_match 'BaSH is planning on micro-injecting', mi.warnings.first
      end

    end

    should_eventually 'be able to generate more than one warning (when we actually have conditions generating more than one)'
  end
end
