# encoding: utf-8

require 'test_helper'

class StatusCodesTest < ActiveSupport::TestCase
  context 'Status codes' do

    should 'be present' do
      assert_equal 'asg', MiPlan::Status[:Assigned].code
      assert_equal 'mip', MiAttempt::Status.micro_injection_in_progress.code
      assert_equal 'par', PhenotypeAttempt::Status.find_by_name!('Phenotype Attempt Registered').code
    end

  end

  context 'Status code shortcuts (found in config/initializers/status_code_extensions.rb)' do

    should 'have shortcut from string' do
      assert_equal MiPlan::Status[:Assigned], 'asg'.status
      assert_equal MiAttempt::Status.micro_injection_in_progress, 'mip'.status
      assert_equal PhenotypeAttempt::Status.find_by_name!('Phenotype Attempt Registered'), 'par'.status
    end

    should 'have shortcut from symbol' do
      assert_equal MiPlan::Status[:Assigned], :asg.status
      assert_equal MiAttempt::Status.micro_injection_in_progress, :mip.status
      assert_equal PhenotypeAttempt::Status.find_by_name!('Phenotype Attempt Registered'), :par.status
    end

  end
end
