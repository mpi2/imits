# encoding: utf-8

require 'test_helper'

class PhenotypeAttempt::StatusTest < ActiveSupport::TestCase
  context 'PhenotypeAttempt::Status' do

    should 'have #name' do
      assert_should have_db_column(:name).with_options(:null => false)
    end

    should 'have #[] shortcut' do
      assert_equal PhenotypeAttempt::Status.find_by_name!('Phenotype Attempt Registered'),
              PhenotypeAttempt::Status['Phenotype Attempt Registered']

      s = PhenotypeAttempt::Status.create!(:name => 'Nonexistent')
      assert_equal s, PhenotypeAttempt::Status[:Nonexistent]
    end

  end
end
