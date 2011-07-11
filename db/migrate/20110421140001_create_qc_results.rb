class CreateQcResults < ActiveRecord::Migration
  def self.up
    create_table :qc_results do |t|
      t.string :description, :null => false, :limit => 50
      t.timestamps
    end

    add_index :qc_results, :description, :unique => true
  end

  def self.down
    drop_table :qc_results
  end
end
