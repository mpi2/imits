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

  def self.setup_access
    access_association_by_attribute :owner, :name
  end
end

class AccessAssociationByAttributeTest < ActiveSupport::TestCase
  context 'access_association_by_attribute' do

    setup do
      @person1 = InMemoryPerson.create! :name => 'Fred'
      @person2 = InMemoryPerson.create! :name => 'Ali'

      @pet = InMemoryPet.new :name => 'Spot', :animal => 'Dog', :owner => @person1
    end

    context 'on getting' do
      setup do
        InMemoryPet.setup_access
      end

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
      setup do
        InMemoryPet.setup_access
      end

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
      setup do
        InMemoryPet.setup_access
      end

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

      should 'allow unsetting association by passing nil' do
        @pet.owner_name = nil
        @pet.save!
        @pet.reload
        assert_equal nil, @pet.owner
      end

      should 'allow unsetting association by passing anything blank' do
        @pet.owner_name = ''
        @pet.save!
        @pet.reload
        assert_equal nil, @pet.owner
      end
    end

    context 'on saving with invalid assignment' do
      setup do
        InMemoryPet.setup_access
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

    context 'attribute alias' do
      setup do
        class ::InMemoryPet
          access_association_by_attribute :owner, :name, :attribute_alias => :full_name
        end
      end

      should 'when configured also allow access via alias' do
        @pet.owner_full_name = @person2.name
        assert_equal @person2.name, @pet.owner_full_name
      end
    end

  end
end
