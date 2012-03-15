# encoding: utf-8

require 'test_helper'

class ContactTest < ActiveSupport::TestCase
  
  context 'Contact' do
    
    def default_contact
      @default_contact ||= Factory.create :contact
    end
    
    context 'attribute tests:' do
      should 'have associations' do
        assert_should have_many :genes
      end

      should 'have db columns' do
        assert_should have_db_column(:email).with_options(:null => false)
        assert_should have_db_column(:first_name)
        assert_should have_db_column(:last_name)
        assert_should have_db_column(:institution)
        assert_should have_db_column(:organisation)
      end
    end
    
  end
  
end
