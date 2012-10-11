# encoding: utf-8

require 'test_helper'

class PhenotypeAttempt::StatusTest < ActiveSupport::TestCase
  context 'PhenotypeAttempt::Status' do

    should 'have #name' do
      assert_should have_db_column(:name).with_options(:null => false)
    end

    should 'include StatusInterface' do
      assert_include PhenotypeAttempt::Status.ancestors, StatusInterface
    end

  end
end
