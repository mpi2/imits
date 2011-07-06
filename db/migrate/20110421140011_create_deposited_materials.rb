# encoding: utf-8

class CreateDepositedMaterials < ActiveRecord::Migration
  def self.up
    create_table :deposited_materials do |table|
      table.text :name, :null => false
      table.timestamps
    end
    add_index :deposited_materials, :name, :unique => true
  end

  def self.down
    drop_table :deposited_materials
  end
end
