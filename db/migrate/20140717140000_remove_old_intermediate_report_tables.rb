class RemoveOldIntermediateReportTables < ActiveRecord::Migration
  def self.up
    drop_table :new_intermediate_report
    drop_table :new_gene_intermediate_report
    drop_table :new_consortia_intermediate_report
  end
end
