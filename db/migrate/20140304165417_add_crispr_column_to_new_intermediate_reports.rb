class AddCrisprColumnToNewIntermediateReports < ActiveRecord::Migration
  def change
    add_column :new_intermediate_report, :mutagenesis_via_crispr_cas9, :boolean, :default => false
  end
end
