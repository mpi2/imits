class CreatePipelines < ActiveRecord::Migration
  def self.up
    create_table :pipelines do |t|
      t.string :name, :limit => 50, :null => false
      t.text :description

      t.timestamps
    end

    add_index :pipelines, :name, :unique => true
  end

  def self.down
    drop_table :pipelines
  end
end
