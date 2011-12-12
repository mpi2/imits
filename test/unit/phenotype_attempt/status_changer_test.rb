# encoding: utf-8

require 'test_helper'

class PhenotypeAttempt::StatusChangerTest < ActiveSupport::TestCase
  context 'PhenotypeAttempt::StatusChanger' do

    def phenotype_attempt
      @phenotype_attempt ||= Factory.build :phenotype_attempt
    end

    should 'set default status to Registered' do
      phenotype_attempt.valid?
      assert_equal 'Registered', phenotype_attempt.status.name
    end

    should 'set status to Rederivation Started if its flag is set' do
      phenotype_attempt.rederivation_started = true
      phenotype_attempt.valid?
      assert_equal 'Rederivation Started', phenotype_attempt.status.name
    end

  end
end
