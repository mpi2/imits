class MakeSeparateFormatFieldInReportCaches < ActiveRecord::Migration
  def self.up
    remove_column :report_caches, :html_data
    rename_column :report_caches, :csv_data, :data
    add_column :report_caches, :format, :text, :null => false
  end

  def self.down
    remove_column :report_caches, :format
    rename_column :report_caches, :data, :csv_data
    add_column :report_caches, :html_data, :text, :null => false
  end
end
