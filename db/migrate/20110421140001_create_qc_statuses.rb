class CreateQcStatuses < ActiveRecord::Migration
  def self.up
    create_table :qc_statuses do |t|
      t.text :description, :null => false
      t.timestamps
    end

    add_index :qc_statuses, :description, :unique => true
  end

  def self.down
    drop_table :qc_statuses
  end
end
