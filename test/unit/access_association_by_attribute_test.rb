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

    should 'allow getting the attribute off the associated object' do
      assert_equal @pet.owner.name, @pet.owner_name
    end

    should 'return nil on get if association is nil' do
      @pet.owner = nil
      assert_equal nil, @pet.owner_name
    end

  end
end
