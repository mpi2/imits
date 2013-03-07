class AddReportToPublicToPipelines < ActiveRecord::Migration
  def change
    add_column :targ_rep_pipelines, :report_to_public, :boolean, :default => true
  end
end
