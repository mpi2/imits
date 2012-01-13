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

  end
end
