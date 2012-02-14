# encoding: utf-8

require 'test_helper'

class ApplicationModelTest < ActiveSupport::TestCase
  context 'ApplicationModel' do

    context '::audited_transaction' do
      should 'audit for htgt@sanger.ac.uk if no user given' do
        user = Factory.create :user, :email => 'htgt@sanger.ac.uk'
        assert_equal 0, Audit.count
        ApplicationModel.audited_transaction do
          Test::Person.create!(:name => 'Ali')
        end
        audit = Audit.first
        assert_equal user.id, audit.user_id
      end
    end

  end
end
