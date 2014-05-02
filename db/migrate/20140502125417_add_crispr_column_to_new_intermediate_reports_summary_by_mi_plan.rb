class AddCrisprColumnToNewIntermediateReportsSummaryByMiPlan < ActiveRecord::Migration
  def change
    add_column :new_intermediate_report_summary_by_mi_plan, :mutagenesis_via_crispr_cas9, :boolean, :default => false
  end
end
