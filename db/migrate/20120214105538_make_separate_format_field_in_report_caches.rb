class MakeSeparateFormatFieldInReportCaches < ActiveRecord::Migration
  def self.up
    remove_column :report_caches, :html_data
    rename_column :report_caches, :csv_data, :data
    add_column :report_caches, :format, :text, :null => false
    remove_index :report_caches, :name
    add_index :report_caches, [:name, :format], :unique => true
  end

  def self.down
    remove_index :report_caches, [:name, :format]
    add_index :report_caches, :name, :unique => true
    remove_column :report_caches, :format
    rename_column :report_caches, :data, :csv_data
    add_column :report_caches, :html_data, :text, :null => false
  end
end
