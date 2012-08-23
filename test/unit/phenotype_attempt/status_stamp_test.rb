# encoding: utf-8

require 'test_helper'

class PhenotypeAttempt::StatusStampTest < ActiveSupport::TestCase
  context 'PhenotypeAttempt::StatusStamp' do

    should 'have db fields' do
      assert_should have_db_column(:phenotype_attempt_id).with_options(:null => false)
      assert_should have_db_column(:status_id).with_options(:null => false)
    end

    should 'have db foreign keys' do
      pt = Factory.create :phenotype_attempt
      PhenotypeAttempt::StatusStamp.where(:phenotype_attempt_id => pt.id).each(&:destroy)
      status = PhenotypeAttempt::Status.create!(:name => 'Nonexistent', :code => 'nex')
      ss = PhenotypeAttempt::StatusStamp.create!(:phenotype_attempt => pt,
        :status => status)
      assert_raise(ActiveRecord::InvalidForeignKey) { status.destroy }
      assert_raise(ActiveRecord::InvalidForeignKey) { pt.destroy }
    end

    should 'have #phenotype_attempt' do
      assert_should belong_to :phenotype_attempt
    end

    should 'have associations' do
      assert_should belong_to :status

      pt = Factory.create :phenotype_attempt
      status = PhenotypeAttempt::Status['Phenotype Attempt Registered']
      ss = pt.status_stamps.first
      assert_equal status, ss.status
    end

  end
end
