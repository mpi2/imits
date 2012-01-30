# encoding: utf-8

require 'test_helper'

class Public::PhenotypeAttemptTest < ActiveSupport::TestCase
  context 'Public::PhenotypeAttempt' do

    def default_phenotype_attempt
      @default_phenotype_attempt ||= Public::PhenotypeAttempt.find(Factory.create :phenotype_attempt)
    end

    context '#mi_attempt_colony_name' do
      should 'AccessAssociationByAttribute' do
        mi = Factory.create :mi_attempt, :colony_name => 'ABCD123'
        default_phenotype_attempt.mi_attempt_colony_name = 'ABCD123'
        assert_equal mi, default_phenotype_attempt.mi_attempt
      end

      should 'validate presence' do
        assert_should validate_presence_of :mi_attempt_colony_name
      end

      should 'not be updateable' do
        mi = Factory.create :mi_attempt
        default_phenotype_attempt.mi_attempt_colony_name = mi.colony_name
        default_phenotype_attempt.valid?
        assert_match /cannot be changed/, default_phenotype_attempt.errors[:mi_attempt_colony_name].first
      end

      should 'be able to be set on create' do
        mi = Factory.create :mi_attempt
        phenotype_attempt = Public::PhenotypeAttempt.new(
          :mi_attempt_colony_name => mi.colony_name)
        phenotype_attempt.valid?
        assert phenotype_attempt.errors[:mi_attempt_colony_name].blank?
      end
    end

    context '#consortium_name virtual attribute' do
      should 'be writable with any value which should be returned on a read when no MiPlan is set' do
        pt = Public::PhenotypeAttempt.new :mi_plan => nil, :consortium_name => 'Foo'
        assert_equal 'Foo', pt.consortium_name
      end

      should 'validate the consortium exists for a new record' do
        pt = Public::PhenotypeAttempt.new(:consortium_name => 'Foo')
        pt.valid?
        assert_equal ['does not exist'], pt.errors[:consortium_name]
      end

      should 'validate the consortium cannot be changed on update' do
        assert default_phenotype_attempt
        pt = Public::PhenotypeAttempt.find(default_phenotype_attempt.id)
        assert_not_equal 'JAX', pt.consortium_name

        pt.consortium_name = 'JAX'
        pt.valid?
        assert_equal ['cannot be changed'], pt.errors[:consortium_name], pt.errors.inspect
      end
    end

    context '#production_centre_name virtual attribute' do
      should 'be writable with any value which should be returned on a read when no MiPlan is set' do
        pt = Public::PhenotypeAttempt.new :mi_plan => nil, :production_centre_name => 'Foo'
        assert_equal 'Foo', pt.production_centre_name
      end

      should 'validate the production_centre exists for a new record' do
        pt = Public::PhenotypeAttempt.new(:production_centre_name => 'Foo')
        pt.valid?
        assert_equal ['does not exist'], pt.errors[:production_centre_name]
      end

      should 'validate the production_centre cannot be changed on update' do
        assert default_phenotype_attempt
        pt = Public::PhenotypeAttempt.find(default_phenotype_attempt.id)
        assert_not_equal 'TCP', pt.production_centre_name

        pt.production_centre_name = 'TCP'
        pt.valid?
        assert_equal ['cannot be changed'], pt.errors[:production_centre_name], pt.errors.inspect
      end
    end

    context '#mi_plan' do
      setup do
        @cbx1 = Factory.create(:gene_cbx1)
        @mi = Factory.create(:mi_attempt_genotype_confirmed,
          :es_cell => Factory.create(:es_cell, :gene => @cbx1),
          :consortium_name => 'BaSH',
          :production_centre_name => 'ICS')
      end

      should 'not raise error when being set by before filter if no mi_attempt is found' do
        pt = Public::PhenotypeAttempt.new
        assert_false pt.valid?
      end

      should 'be set to correct MiPlan if neither consortium_name nor production_centre_name are provided' do
        pt = Public::PhenotypeAttempt.new(:mi_attempt_colony_name => @mi.colony_name)
        pt.save!
        assert_equal @mi.mi_plan, pt.mi_plan
      end

      should 'be set to correct MiPlan if only production_centre_name is provided' do
        plan = Factory.create(:mi_plan, :gene => @cbx1,
          :consortium => Consortium.find_by_name!('BaSH'),
          :production_centre => Centre.find_by_name!('UCD'))
        pt = Public::PhenotypeAttempt.new(:mi_attempt_colony_name => @mi.colony_name,
          :production_centre_name => 'UCD')
        pt.save!
        assert_equal plan, pt.mi_plan
      end

      should 'be set to correct MiPlan if only consortium_name is provided' do
        plan = Factory.create(:mi_plan, :gene => @cbx1,
          :consortium => Consortium.find_by_name!('DTCC'),
          :production_centre => Centre.find_by_name!('ICS'))
        pt = Public::PhenotypeAttempt.new(:mi_attempt_colony_name => @mi.colony_name,
          :consortium_name => 'DTCC')
        pt.save!
        assert_equal plan, pt.mi_plan
      end

      should 'be set to correct MiPlan if both consortium_name and production_centre_name are provided' do
        Factory.create(:mi_plan, :gene => @cbx1,
          :production_centre => Centre.find_by_name!('UCD'))
        Factory.create(:mi_plan, :gene => @cbx1,
          :consortium => Consortium.find_by_name!('DTCC'))
        plan = Factory.create(:mi_plan, :gene => @cbx1,
          :consortium => Consortium.find_by_name!('DTCC'),
          :production_centre => Centre.find_by_name!('UCD'))
        pt = Public::PhenotypeAttempt.new(:mi_attempt_colony_name => @mi.colony_name,
          :production_centre_name => 'UCD', :consortium_name => 'DTCC')
        pt.save!
        assert_equal plan, pt.mi_plan
      end

      should 'cause validation error if MiPlan matching supplied parameters does not exist' do
        pt = Public::PhenotypeAttempt.new(:mi_attempt_colony_name => @mi.colony_name,
          :consortium_name => 'DTCC')
        pt.valid?
        assert_match /cannot be found with supplied parameters/i, pt.errors['mi_plan'].first

      end

      should 'set MiPlan to Assigned status if not assigned already' do
        plan = @mi.mi_plan.clone
        plan.consortium = Consortium.find_by_name!('JAX')
        plan.status = MiPlan::Status['Interest']
        plan.save!
        assert_equal 'Interest', plan.status.name

        pt = Public::PhenotypeAttempt.new(:mi_attempt_colony_name => @mi.colony_name,
          :consortium_name => 'JAX')
        pt.save!
        assert_equal plan, pt.mi_plan
        plan.reload; assert_equal 'Assigned', plan.status.name
      end

      should 'not overwrite existing MiPlan that has been assigned' do
        Factory.create :mi_plan, :consortium => Consortium.find_by_name!('DTCC'),
                :production_centre => Centre.find_by_name!('TCP'),
                :gene => @mi.gene

        pt = Public::PhenotypeAttempt.new(:mi_attempt_colony_name => @mi.colony_name,
          :consortium_name => 'DTCC', :production_centre_name => 'TCP')
        plan = Factory.create :mi_plan, :consortium => Consortium.find_by_name!('DTCC'),
                :production_centre => Centre.find_by_name!('UCD'),
                :gene => @mi.gene
        pt.mi_plan = plan
        pt.valid?
        assert_equal plan, pt.mi_plan
      end
    end

  end
end
