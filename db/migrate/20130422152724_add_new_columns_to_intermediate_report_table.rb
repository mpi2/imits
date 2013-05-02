class AddNewColumnsToIntermediateReportTable < ActiveRecord::Migration
  def change
    add_column :intermediate_report, :distinct_non_genotype_confirmed_es_cells, :integer
    add_column :intermediate_report, :distinct_old_genotype_confirmed_es_cells, :integer
    add_column :intermediate_report, :total_old_pipeline_efficiency_gene_count, :integer
    add_column :intermediate_report, :gc_old_pipeline_efficiency_gene_count, :integer
  end
end