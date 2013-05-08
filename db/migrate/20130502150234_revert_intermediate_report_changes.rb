class RevertIntermediateReportChanges < ActiveRecord::Migration
  def up
    IntermediateReport.where(:allele_symbol => nil).each {|r| r.update_attribute(:allele_symbol, '')}
    IntermediateReport.where(:genetic_background => nil).each {|r| r.update_attribute(:genetic_background, '')}
    IntermediateReport.where(:production_centre => nil).each {|r| r.update_attribute(:production_centre, '')}
    IntermediateReport.where(:sub_project => nil).each {|r| r.update_attribute(:sub_project, '')}

    change_column :intermediate_report, :allele_symbol, :string, :null => false
    change_column :intermediate_report, :genetic_background, :string, :null => false
    change_column :intermediate_report, :production_centre, :string, :null => false
    change_column :intermediate_report, :sub_project, :string, :null => false

    remove_column :intermediate_report, :distinct_non_genotype_confirmed_es_cells
    remove_column :intermediate_report, :distinct_old_genotype_confirmed_es_cells
    remove_column :intermediate_report, :total_old_pipeline_efficiency_gene_count
    remove_column :intermediate_report, :gc_old_pipeline_efficiency_gene_count
  end

  def down
    change_column :intermediate_report, :allele_symbol, :string, :null => true
    change_column :intermediate_report, :genetic_background, :string, :null => true
    change_column :intermediate_report, :production_centre, :string, :null => true
    change_column :intermediate_report, :sub_project, :string, :null => true

    add_column :intermediate_report, :distinct_non_genotype_confirmed_es_cells, :integer
    add_column :intermediate_report, :distinct_old_genotype_confirmed_es_cells, :integer
    add_column :intermediate_report, :total_old_pipeline_efficiency_gene_count, :integer
    add_column :intermediate_report, :gc_old_pipeline_efficiency_gene_count, :integer
  end
end
