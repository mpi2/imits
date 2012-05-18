class AddEfficiencyColumnsToIntermediateReport < ActiveRecord::Migration
  def self.up
    add_column :intermediate_report, :total_pipeline_efficiency_gene_count, :int
    add_column :intermediate_report, :gc_pipeline_efficiency_gene_count, :int
  end

  def self.down
    remove_column :intermediate_report, :gc_pipeline_efficiency_gene_count
    remove_column :intermediate_report, :total_pipeline_efficiency_gene_count
  end
end
