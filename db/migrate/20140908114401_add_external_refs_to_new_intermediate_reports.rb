class AddExternalRefsToNewIntermediateReports < ActiveRecord::Migration

  def self.up

    add_column :new_intermediate_report_summary_by_mi_plan, :mi_attempt_external_ref, :string

    add_column :new_intermediate_report_summary_by_centre_and_consortia, :mi_attempt_external_ref, :string

    add_column :new_intermediate_report_summary_by_consortia, :mi_attempt_external_ref, :string
  end


  def self.down
    remove_column :new_intermediate_report_summary_by_mi_plan, :mi_attempt_external_ref

    remove_column :new_intermediate_report_summary_by_centre_and_consortia, :mi_attempt_external_ref

    remove_column :new_intermediate_report_summary_by_consortia, :mi_attempt_external_ref
  end
end
