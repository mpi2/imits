class AddHtmlDataToReportCaches < ActiveRecord::Migration
  def self.up
    add_column :report_caches, :html_data, :text, :null => false
  end

  def self.down
    remove_column :report_caches, :html_data
  end
end
