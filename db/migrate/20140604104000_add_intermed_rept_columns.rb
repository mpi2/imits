class AddIntermedReptColumns < ActiveRecord::Migration
  def change
    add_column :new_intermediate_report_summary_by_consortia, :sub_project, :string
    add_column :new_intermediate_report_summary_by_consortia, :mutation_sub_type, :string, :limit=>100
	add_column :new_intermediate_report_summary_by_centre_and_consortia, :sub_project, :string
    add_column :new_intermediate_report_summary_by_centre_and_consortia, :mutation_sub_type, :string, :limit=>100
  end
end