class CreateQcResults < ActiveRecord::Migration
  def self.up
    create_table :qc_results do |t|
      t.text :description, :null => false
      t.timestamps
    end

    add_index :qc_results, :description, :unique => true
  end

  def self.down
    drop_table :qc_results
  end
end
