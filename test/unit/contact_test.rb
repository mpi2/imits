# encoding: utf-8

require 'test_helper'

class ContactTest < ActiveSupport::TestCase

  setup do
    Factory.create :contact
  end

  context 'Contact' do

    context 'database table' do
      should have_db_column(:id).of_type(:integer).with_options(:primary => true)
      should have_db_column(:email).of_type(:string).with_options(:null => false, :limit => 255)
      should have_db_column(:created_at).of_type(:datetime)
      should have_db_column(:updated_at).of_type(:datetime)
      should have_db_column(:report_to_public).of_type(:boolean).with_options(:default => true)

      should have_db_index(:email).unique(true)
    end

    context 'Associations and Validations' do
      should validate_presence_of :email
      should validate_uniqueness_of :email

      should have_many :genes
      should have_many :notifications
    end

    should 'have accessible attributes' do
      accessible_attr = [:email, :report_to_public]

      accessible_attr.each do |attribute|
        assert_include Contact.accessible_attributes, attribute, "Missing attribute #{attribute}"
      end

      # remove id fields from accessible_attributes by using access_association_by_attribute
      Contact.accessible_attributes.each do |attribute|
        assert_include accessible_attr, attribute.to_sym, "Extra attribute detected #{attribute}"
      end      
    end

    should 'write tests for accepts_nested_attributes_for' do
      assert false
    end
  end

end
