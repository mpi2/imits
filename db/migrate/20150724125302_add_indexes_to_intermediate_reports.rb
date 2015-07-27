class AddIndexesToIntermediateReports < ActiveRecord::Migration

  def self.up

    add_index :intermediate_report_summary_by_gene, :gene, name: 'irsg_gene'
    add_index :intermediate_report_summary_by_centre, [:gene :centre], name: 'irscen_gene_centre'
    add_index :intermediate_report_summary_by_centre_and_consortia, [:gene :centre :consortium], name: 'irscen_gene_centre_consortia'
    add_index :intermediate_report_summary_by_consortia, [:gene :consortium], name: 'irscen_gene_consortia'

  end

end
