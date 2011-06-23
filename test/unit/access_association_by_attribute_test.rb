# encoding: utf-8

require 'test_helper'

class InMemoryPet < ActiveRecord::Base
  extend AccessAssociationByAttribute

  self.establish_connection IN_MEMORY_MODEL_CONNECTION_PARAMS

  self.connection.create_table :in_memory_pets do |t|
    t.integer :owner_id
    t.text    :name
    t.text    :animal
  end

  belongs_to :owner, :class_name => 'InMemoryPerson'

  access_association_by_attribute :owner, :name
end

class AccessAssociationByAttributeTest < ActiveSupport::TestCase
  context 'access_association_by_attribute' do

    setup do
      @person1 = InMemoryPerson.create! :name => 'Fred'
      @person2 = InMemoryPerson.create! :name => 'Ali'

      @pet = InMemoryPet.new :name => 'Spot', :animal => 'Dog', :owner => @person1
    end

    context 'on getting' do
      should 'allow getting the attribute of the associated object' do
        assert_equal @pet.owner.name, @pet.owner_name
      end

      should 'return nil if association is nil' do
        @pet.owner = nil
        assert_equal nil, @pet.owner_name
      end

      should 'set an instance variable "@name" in object containing with default value' do
        @pet.owner_name
        assert_equal 'Fred', @pet.instance_variable_get('@owner_name')
      end
    end

    context 'on setting' do
      should 'return set value on a get' do
        @pet.owner_name = 'Ali'
        assert_equal 'Ali', @pet.owner_name
      end

      should 'set an instance variable "@name" in object' do
        assert_false @pet.instance_variable_defined?('@owner_name')
        @pet.owner_name = 'A Name'
        assert_equal 'A Name', @pet.instance_variable_get('@owner_name')
      end
    end

    context 'on saving with valid assignment' do
      should 'set association by given attribute value' do
        @pet.owner_name = 'Ali'
        @pet.save!
        @pet.reload
        assert_equal 'Ali', @pet.owner.name
      end

      should 'set correctly even if association was previously unset' do
        @pet.owner = nil
        @pet.owner_name = 'Ali'
        @pet.save!
        @pet.reload
        assert_equal 'Ali', @pet.owner.name
      end
    end

    context 'on saving with invalid assignment' do
      setup do
        @pet.owner_name = 'Nonexistent'
        assert_false @pet.save
      end

      should 'cause validation errors if requested association object does not exist' do
        assert_include @pet.errors[:owner_name], "'Nonexistent' does not exist"
      end

      should 'still return incorrect value that caused error (just like setting a real attribute incorrectly would)' do
        assert_equal 'Nonexistent', @pet.owner_name
      end
    end

  end
end
