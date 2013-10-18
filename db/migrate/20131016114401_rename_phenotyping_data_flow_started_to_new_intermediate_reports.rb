class RenamePhenotypingDataFlowStartedToNewIntermediateReports < ActiveRecord::Migration

  def self.up
    rename_column :new_intermediate_report, :phenotyping_data_flow_started_date, :phenotyping_experiments_started_date
    rename_column :new_intermediate_report, :non_cre_ex_phenotyping_data_flow_started_date, :non_cre_ex_phenotyping_experiments_started_date
    rename_column :new_intermediate_report, :cre_ex_phenotyping_data_flow_started_date, :cre_ex_phenotyping_experiments_started_date

    rename_column :new_gene_intermediate_report, :phenotyping_data_flow_started_date, :phenotyping_experiments_started_date
    rename_column :new_gene_intermediate_report, :non_cre_ex_phenotyping_data_flow_started_date, :non_cre_ex_phenotyping_experiments_started_date
    rename_column :new_gene_intermediate_report, :cre_ex_phenotyping_data_flow_started_date, :cre_ex_phenotyping_experiments_started_date

    rename_column :new_consortia_intermediate_report, :phenotyping_data_flow_started_date, :phenotyping_experiments_started_date
    rename_column :new_consortia_intermediate_report, :non_cre_ex_phenotyping_data_flow_started_date, :non_cre_ex_phenotyping_experiments_started_date
    rename_column :new_consortia_intermediate_report, :cre_ex_phenotyping_data_flow_started_date, :cre_ex_phenotyping_experiments_started_date
  end

  def self.down
    rename_column :new_intermediate_report, :phenotyping_experiments_started_date, :phenotyping_data_flow_started_date
    rename_column :new_intermediate_report, :non_cre_ex_phenotyping_experiments_started_date, :non_cre_ex_phenotyping_data_flow_started_date
    rename_column :new_intermediate_report, :cre_ex_phenotyping_experiments_started_date, :cre_ex_phenotyping_data_flow_started_date

    rename_column :new_gene_intermediate_report, :phenotyping_experiments_started_date, :phenotyping_data_flow_started_date
    rename_column :new_gene_intermediate_report, :non_cre_ex_phenotyping_experiments_started_date, :non_cre_ex_phenotyping_data_flow_started_date
    rename_column :new_gene_intermediate_report, :cre_ex_phenotyping_experiments_started_date, :cre_ex_phenotyping_data_flow_started_date

    rename_column :new_consortia_intermediate_report, :phenotyping_experiments_started_date, :phenotyping_data_flow_started_date
    rename_column :new_consortia_intermediate_report, :non_cre_ex_phenotyping_experiments_started_date, :non_cre_ex_phenotyping_data_flow_started_date
    rename_column :new_consortia_intermediate_report, :cre_ex_phenotyping_experiments_started_date, :cre_ex_phenotyping_data_flow_started_date
  end
end
