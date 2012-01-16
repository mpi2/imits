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

      should 'validate the consortium cannot be changed if MiPlan is assigned' do
        mi = Factory.create :mi_attempt_genotype_confirmed
        Factory.create(:mi_plan, :consortium => Consortium.find_by_name!('JAX'),
          :gene => mi.gene, :production_centre => mi.production_centre)
        mi_plan = Factory.create(:mi_plan, :consortium => Consortium.find_by_name!('BaSH'))
        pt = Public::PhenotypeAttempt.new(:mi_attempt_colony_name => mi.colony_name,
          :mi_plan => mi_plan, :consortium_name => 'JAX')
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

      should 'validate the production_centre cannot be changed if MiPlan is assigned' do
        mi = Factory.create :mi_attempt_genotype_confirmed
        mi_plan = Factory.create(:mi_plan, :production_centre => Centre.find_by_name!('ICS'))
        pt = Public::PhenotypeAttempt.new(:mi_attempt_colony_name => mi.colony_name,
          :mi_plan => mi_plan, :production_centre_name => 'WTSI')
        pt.valid?
        assert_equal ['cannot be changed'], pt.errors[:production_centre_name]
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
    end

  end
end
