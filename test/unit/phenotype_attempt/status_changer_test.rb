# encoding: utf-8

require 'test_helper'

class PhenotypeAttempt::StatusChangerTest < ActiveSupport::TestCase
  context 'PhenotypeAttempt::StatusChanger' do

    context '::change_status' do
      should 'default status to Registered' do
        pt = PhenotypeAttempt.new
        pt.valid?
        assert_equal PhenotypeAttempt::Status['Registered'], pt.status
      end
    end

  end
end
