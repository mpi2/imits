# encoding: utf-8

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  context 'User' do

    setup do
      Factory.create :user
    end

    context 'database table' do
      should have_db_column(:id).of_type(:integer).with_options(:primary => true)
      should have_db_column(:email).of_type(:string).with_options(:null => false, :limit => 255)
      should have_db_column(:encrypted_password).of_type(:string).with_options(:limit => 128)
      should have_db_column(:remember_created_at).of_type(:datetime)
      should have_db_column(:production_centre_id).of_type(:integer)
      should have_db_column(:created_at).of_type(:datetime)
      should have_db_column(:updated_at).of_type(:datetime)
      should have_db_column(:name).of_type(:string).with_options(:limit => 255)
      should have_db_column(:is_contactable).of_type(:boolean).with_options(:default => false)
      should have_db_column(:reset_password_token).of_type(:string).with_options(:limit => 255)
      should have_db_column(:reset_password_sent_at).of_type(:datetime)
      should have_db_column(:es_cell_distribution_centre_id).of_type(:integer)
      should have_db_column(:legacy_id).of_type(:integer)
      should have_db_column(:admin).of_type(:boolean).with_options(:default => false)
      should have_db_column(:active).of_type(:boolean).with_options(:default => true)
      should have_db_column(:filter_by_centre_id).of_type(:string).with_options(:limit => 255)

      should have_db_index(:email).unique(true)
    end

    context 'Associations and Validations' do
      should validate_presence_of :email
      should validate_uniqueness_of :email
      should validate_presence_of :production_centre_id

      should belong_to :production_centre
      should belong_to :filter_by_centre
      should belong_to :es_cell_distribution_centre
    end


    should 'have accessible attributes' do
      accessible_attr = [:email, :password, :password_confirmation, :remember_me, :production_centre, 
                               :production_centre_id, :filter_by_centre_name, :name, :is_contactable]

      accessible_attr.each do |attribute|
        assert_include User.accessible_attributes, attribute, "Missing attribute #{attribute}"
      end

      # remove id fields from accessible_attributes by using access_association_by_attribute
      User.accessible_attributes.each do |attribute|
        assert_include accessible_attr, attribute.to_sym, "Extra attribute detected #{attribute}"
      end      
    end

    context '#remember_me' do
      should 'be true by default' do
        assert_equal true, subject.remember_me
      end
    end

    should 'have #admin? users' do
      assert_true Factory.create(:admin_user).admin?
      assert_false Factory.create(:user).admin?
    end

    should 'have #remote? users' do
      assert false, "Is this still needed. Move configuration to model."
    end

    context '#can_see_sub_project?' do
      should 'be false for non-WTSI-JAX users' do
        user = Factory.create :user, :production_centre => Centre.find_by_name!('ICS')
        assert_false user.can_see_sub_project?
      end

      should 'be true for WTSI users' do
        user = Factory.create :user, :production_centre => Centre.find_by_name!('WTSI')
        assert_true user.can_see_sub_project?
      end

      should 'be true for JAX users' do
        user = Factory.create :user, :production_centre => Centre.find_by_name!('JAX')
        assert_true user.can_see_sub_project?
      end
    end

    should 'have production_centre_name method' do
      user = Factory.create :user, :production_centre => Centre.find_by_name!('JAX')
      assert_equal user.production_centre_name, 'JAX'
    end

    should 'have filter_by_centre_name method' do
      user = Factory.create :user, :filter_by_centre => Centre.find_by_name!('JAX')
      assert_equal user.filter_by_centre_name, 'JAX'
    end

  end
end
