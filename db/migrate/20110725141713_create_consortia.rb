class CreateConsortia < ActiveRecord::Migration
  def self.up
    create_table :consortia do |t|
      t.string :name, :null => false, :size => 15
      t.timestamps
    end
    add_index :consortia, :name, :unique => true

    add_column :mi_attempts, :consortium_id, :integer
    add_foreign_key :mi_attempts, :consortia

    add_column :users, :consortium_id, :integer
    add_foreign_key :users, :consortia
  end

  def self.down
    remove_foreign_key :users, :consortia
    remove_column :users, :consortium_id

    remove_foreign_key :mi_attempts, :consortia
    remove_column :mi_attempts, :consortium_id

    remove_index :consortia, :column => :name
    drop_table :consortia
  end
end
