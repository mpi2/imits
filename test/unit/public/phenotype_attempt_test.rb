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
        pt = Public::PhenotypeAttempt.new(:consortium_name => 'JAX')
        pt.mi_plan = Factory.create(:mi_plan, :consortium => Consortium.find_by_name!('BaSH'))
        pt.valid?
        assert_equal ['cannot be changed'], pt.errors[:consortium_name]
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
        pt = Public::PhenotypeAttempt.new(:production_centre_name => 'WTSI')
        pt.mi_plan = Factory.create(:mi_plan, :production_centre => Centre.find_by_name!('ICS'))
        pt.valid?
        assert_equal ['cannot be changed'], pt.errors[:production_centre_name]
      end
    end

  end
end
