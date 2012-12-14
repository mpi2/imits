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

    context '::to_public_class' do
      should 'work' do
        assert_equal Public::MiPlan, MiPlan.to_public_class
      end
    end

    context '#to_public' do
      should 'work' do
        p = Factory.create :mi_plan
        assert_equal Public::MiPlan, p.to_public.class
      end
    end

  end
end
