class AddPhenotypingDataFlowStartedToNewIntermediateReports < ActiveRecord::Migration

  def self.up
    add_column :new_intermediate_report, :phenotyping_data_flow_started_date, :date
    add_column :new_intermediate_report, :non_cre_ex_phenotyping_data_flow_started_date, :date
    add_column :new_intermediate_report, :cre_ex_phenotyping_data_flow_started_date, :date

    add_column :new_gene_intermediate_report, :phenotyping_data_flow_started_date, :date
    add_column :new_gene_intermediate_report, :non_cre_ex_phenotyping_data_flow_started_date, :date
    add_column :new_gene_intermediate_report, :cre_ex_phenotyping_data_flow_started_date, :date

    add_column :new_consortia_intermediate_report, :phenotyping_data_flow_started_date, :date
    add_column :new_consortia_intermediate_report, :non_cre_ex_phenotyping_data_flow_started_date, :date
    add_column :new_consortia_intermediate_report, :cre_ex_phenotyping_data_flow_started_date, :date
  end

  def self.down
    remove_column :new_intermediate_report, :phenotyping_data_flow_started_date
    remove_column :new_intermediate_report, :non_cre_ex_phenotyping_data_flow_started_date
    remove_column :new_intermediate_report, :cre_ex_phenotyping_data_flow_started_date

    remove_column :new_gene_intermediate_report, :phenotyping_data_flow_started_date
    remove_column :new_gene_intermediate_report, :non_cre_ex_phenotyping_data_flow_started_date
    remove_column :new_gene_intermediate_report, :cre_ex_phenotyping_data_flow_started_date

    remove_column :new_consortia_intermediate_report, :phenotyping_data_flow_started_date
    remove_column :new_consortia_intermediate_report, :non_cre_ex_phenotyping_data_flow_started_date
    remove_column :new_consortia_intermediate_report, :cre_ex_phenotyping_data_flow_started_date
  end
end
