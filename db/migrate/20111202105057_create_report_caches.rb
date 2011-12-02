class CreateReportCaches < ActiveRecord::Migration
  def self.up
    create_table :report_caches do |t|
      t.text :name, :null => false
      t.text :csv_data, :null => false

      t.timestamps
    end

    add_index :report_caches, :name, :unique => true
  end

  def self.down
    drop_table :report_caches
  end
end
