class AddReportToPiblicColumnsToMiPlanAndMiAttempt < ActiveRecord::Migration
  def self.up
    add_column :mi_plans, :report_to_public, :boolean, :default => true, :null => false
    add_column :phenotype_attempts, :report_to_public, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :mi_plans, :report_to_public
    remove_column :phenotype_attempts, :report_to_public
  end
end
