class CreatePipelines < ActiveRecord::Migration
  def self.up
    create_table :pipelines do |t|
      t.text :name, :null => false
      t.text :description, :null => false

      t.timestamps
    end
    add_index :pipelines, :name, :unique => true
  end

  def self.down
    drop_table :pipelines
  end
end
