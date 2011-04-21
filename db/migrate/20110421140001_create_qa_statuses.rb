class CreateQaStatuses < ActiveRecord::Migration
  def self.up
    create_table :qa_statuses do |t|
      t.text :description, :null => false
      t.timestamps
    end

    add_index :qa_statuses, :description, :unique => true
  end

  def self.down
    drop_table :qa_statuses
  end
end
