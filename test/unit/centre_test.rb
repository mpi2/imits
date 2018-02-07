# encoding: utf-8

require 'test_helper'

class CentreTest < ActiveSupport::TestCase
  context 'Centre' do

    setup do
      Factory.create :centre
    end

    context 'database table' do
      should have_db_column(:id).of_type(:integer).with_options(:primary => true)
      should have_db_column(:name).of_type(:string).with_options(:null => false, :limit => 100)
      should have_db_column(:created_at).of_type(:datetime)
      should have_db_column(:updated_at).of_type(:datetime)
      should have_db_column(:contact_name).of_type(:string).with_options(:limit => 100)
      should have_db_column(:contact_email).of_type(:string).with_options(:limit => 100)
      should have_db_column(:code).of_type(:string).with_options(:limit => 255)
      should have_db_column(:superscript).of_type(:string).with_options(:limit => 255)
      should have_db_column(:full_name).of_type(:string).with_options(:limit => 255)

      should have_db_index(:name).unique(true)
    end

    context 'Associations and Validations' do
      should validate_presence_of :name
      should validate_uniqueness_of :name
      should have_many :mi_plans
      should have_many :colony_distribution_centres
      should have_many(:tracking_goals)
    end

    should 'order by name by default' do
      Centre.destroy_all
      Factory.create :centre, :name => 'AA9'
      Factory.create :centre, :name => 'ZZ2'
      Factory.create :centre, :name => 'ZZ1'
      Factory.create :centre, :name => 'AA1'

      assert_equal ['AA1', 'AA9', 'ZZ1', 'ZZ2'], Centre.all.map(&:name)
    end

    context 'instance methods' do
      should 'have a method has_children?' do
        centre = Factory.build :centre
        assert_respond_to centre, :has_children?
      end
      context 'has_children?' do
        should 'return true' do
          assert false, 'Please write a test to test this method'
        end
        should 'return false if not used' do
          centre = Factory.create :centre
          assert !centre.has_children?
        end
      end

      context 'destroy' do
        should 'fail' do
          centre = Factory.create :centre
          centre.expects(:has_children?).returns(true)
          assert !centre.destroy
        end
        should 'succeed' do
          centre = Factory.create :centre
          centre.expects(:has_children?).returns(false)
          assert centre.destroy
          assert_raise( ActiveRecord::RecordNotFound){
            Centre.find(centre.id)
          }
        end
      end
    end
    
    context 'class methods' do
      should 'have a method readable_name' do
        assert_respond_to Centre, :readable_name
        assert_equal Centre.readable_name, 'centre'
      end
    end
  end
end
