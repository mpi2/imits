# encoding: utf-8

require 'test_helper'

class SyncClonesWithMartsTest < ActiveSupport::TestCase
  context './script/one_time/reset_passwords.rb' do

    should 'work' do
      users = [
        Factory.create(:user, :email => 'email1@example.com'),
        Factory.create(:user, :email => 'email2@example.com'),
        Factory.create(:user, :email => 'email3@example.com')
      ]

      load(Rails.root + 'script/one_time/reset_passwords.rb')

      emails = ActionMailer::Base.deliveries.sort_by {|i| i.to.first}

      users.zip(emails).each do |user, email|
        assert_equal user.email, email.to.first
        assert_match /password:\s*\S+/mi, email.body
        assert_match 'http://example.com/kermits2', email.body
      end
    end

  end
end
