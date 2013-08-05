class ChangeNewIntermediateReports < ActiveRecord::Migration

  def self.up
    add_column :new_intermediate_report, :non_cre_ex_phenotype_attempt_status, :string
    add_column :new_intermediate_report, :non_cre_ex_phenotype_attempt_registered_date, :date
    add_column :new_intermediate_report, :non_cre_ex_rederivation_started_date, :date
    add_column :new_intermediate_report, :non_cre_ex_rederivation_complete_date, :date
    add_column :new_intermediate_report, :non_cre_ex_cre_excision_started_date, :date
    add_column :new_intermediate_report, :non_cre_ex_cre_excision_complete_date, :date
    add_column :new_intermediate_report, :non_cre_ex_phenotyping_started_date, :date
    add_column :new_intermediate_report, :non_cre_ex_phenotyping_complete_date, :date
    add_column :new_intermediate_report, :non_cre_ex_phenotype_attempt_aborted_date, :date
    add_column :new_intermediate_report, :non_cre_ex_pa_mouse_allele_type, :string
    add_column :new_intermediate_report, :non_cre_ex_pa_allele_symbol_superscript_template, :string
    add_column :new_intermediate_report, :non_cre_ex_pa_allele_symbol_superscript, :string
    add_column :new_intermediate_report, :non_cre_ex_mi_attempt_consortium, :string
    add_column :new_intermediate_report, :non_cre_ex_mi_attempt_production_centre, :string
    add_column :new_intermediate_report, :non_cre_ex_phenotype_attempt_colony_name, :string
    add_column :new_intermediate_report, :cre_ex_phenotype_attempt_status, :string
    add_column :new_intermediate_report, :cre_ex_phenotype_attempt_registered_date, :date
    add_column :new_intermediate_report, :cre_ex_rederivation_started_date, :date
    add_column :new_intermediate_report, :cre_ex_rederivation_complete_date, :date
    add_column :new_intermediate_report, :cre_ex_cre_excision_started_date, :date
    add_column :new_intermediate_report, :cre_ex_cre_excision_complete_date, :date
    add_column :new_intermediate_report, :cre_ex_phenotyping_started_date, :date
    add_column :new_intermediate_report, :cre_ex_phenotyping_complete_date, :date
    add_column :new_intermediate_report, :cre_ex_phenotype_attempt_aborted_date, :date
    add_column :new_intermediate_report, :cre_ex_pa_mouse_allele_type, :string
    add_column :new_intermediate_report, :cre_ex_pa_allele_symbol_superscript_template, :string
    add_column :new_intermediate_report, :cre_ex_pa_allele_symbol_superscript, :string
    add_column :new_intermediate_report, :cre_ex_mi_attempt_consortium, :string
    add_column :new_intermediate_report, :cre_ex_mi_attempt_production_centre, :string
    add_column :new_intermediate_report, :cre_ex_phenotype_attempt_colony_name, :string

    add_column :new_gene_intermediate_report, :non_cre_ex_phenotype_attempt_status, :string
    add_column :new_gene_intermediate_report, :non_cre_ex_phenotype_attempt_registered_date, :date
    add_column :new_gene_intermediate_report, :non_cre_ex_rederivation_started_date, :date
    add_column :new_gene_intermediate_report, :non_cre_ex_rederivation_complete_date, :date
    add_column :new_gene_intermediate_report, :non_cre_ex_cre_excision_started_date, :date
    add_column :new_gene_intermediate_report, :non_cre_ex_cre_excision_complete_date, :date
    add_column :new_gene_intermediate_report, :non_cre_ex_phenotyping_started_date, :date
    add_column :new_gene_intermediate_report, :non_cre_ex_phenotyping_complete_date, :date
    add_column :new_gene_intermediate_report, :non_cre_ex_phenotype_attempt_aborted_date, :date
    add_column :new_gene_intermediate_report, :non_cre_ex_pa_mouse_allele_type, :string
    add_column :new_gene_intermediate_report, :non_cre_ex_pa_allele_symbol_superscript_template, :string
    add_column :new_gene_intermediate_report, :non_cre_ex_pa_allele_symbol_superscript, :string
    add_column :new_gene_intermediate_report, :non_cre_ex_mi_attempt_consortium, :string
    add_column :new_gene_intermediate_report, :non_cre_ex_mi_attempt_production_centre, :string
    add_column :new_gene_intermediate_report, :non_cre_ex_phenotype_attempt_colony_name, :string
    add_column :new_gene_intermediate_report, :cre_ex_phenotype_attempt_status, :string
    add_column :new_gene_intermediate_report, :cre_ex_phenotype_attempt_registered_date, :date
    add_column :new_gene_intermediate_report, :cre_ex_rederivation_started_date, :date
    add_column :new_gene_intermediate_report, :cre_ex_rederivation_complete_date, :date
    add_column :new_gene_intermediate_report, :cre_ex_cre_excision_started_date, :date
    add_column :new_gene_intermediate_report, :cre_ex_cre_excision_complete_date, :date
    add_column :new_gene_intermediate_report, :cre_ex_phenotyping_started_date, :date
    add_column :new_gene_intermediate_report, :cre_ex_phenotyping_complete_date, :date
    add_column :new_gene_intermediate_report, :cre_ex_phenotype_attempt_aborted_date, :date
    add_column :new_gene_intermediate_report, :cre_ex_pa_mouse_allele_type, :string
    add_column :new_gene_intermediate_report, :cre_ex_pa_allele_symbol_superscript_template, :string
    add_column :new_gene_intermediate_report, :cre_ex_pa_allele_symbol_superscript, :string
    add_column :new_gene_intermediate_report, :cre_ex_mi_attempt_consortium, :string
    add_column :new_gene_intermediate_report, :cre_ex_mi_attempt_production_centre, :string
    add_column :new_gene_intermediate_report, :cre_ex_phenotype_attempt_colony_name, :string

    add_column :new_consortia_intermediate_report, :non_cre_ex_phenotype_attempt_status, :string
    add_column :new_consortia_intermediate_report, :non_cre_ex_phenotype_attempt_registered_date, :date
    add_column :new_consortia_intermediate_report, :non_cre_ex_rederivation_started_date, :date
    add_column :new_consortia_intermediate_report, :non_cre_ex_rederivation_complete_date, :date
    add_column :new_consortia_intermediate_report, :non_cre_ex_cre_excision_started_date, :date
    add_column :new_consortia_intermediate_report, :non_cre_ex_cre_excision_complete_date, :date
    add_column :new_consortia_intermediate_report, :non_cre_ex_phenotyping_started_date, :date
    add_column :new_consortia_intermediate_report, :non_cre_ex_phenotyping_complete_date, :date
    add_column :new_consortia_intermediate_report, :non_cre_ex_phenotype_attempt_aborted_date, :date
    add_column :new_consortia_intermediate_report, :non_cre_ex_pa_mouse_allele_type, :string
    add_column :new_consortia_intermediate_report, :non_cre_ex_pa_allele_symbol_superscript_template, :string
    add_column :new_consortia_intermediate_report, :non_cre_ex_pa_allele_symbol_superscript, :string
    add_column :new_consortia_intermediate_report, :non_cre_ex_mi_attempt_consortium, :string
    add_column :new_consortia_intermediate_report, :non_cre_ex_mi_attempt_production_centre, :string
    add_column :new_consortia_intermediate_report, :non_cre_ex_phenotype_attempt_colony_name, :string
    add_column :new_consortia_intermediate_report, :cre_ex_phenotype_attempt_status, :string
    add_column :new_consortia_intermediate_report, :cre_ex_phenotype_attempt_registered_date, :date
    add_column :new_consortia_intermediate_report, :cre_ex_rederivation_started_date, :date
    add_column :new_consortia_intermediate_report, :cre_ex_rederivation_complete_date, :date
    add_column :new_consortia_intermediate_report, :cre_ex_cre_excision_started_date, :date
    add_column :new_consortia_intermediate_report, :cre_ex_cre_excision_complete_date, :date
    add_column :new_consortia_intermediate_report, :cre_ex_phenotyping_started_date, :date
    add_column :new_consortia_intermediate_report, :cre_ex_phenotyping_complete_date, :date
    add_column :new_consortia_intermediate_report, :cre_ex_phenotype_attempt_aborted_date, :date
    add_column :new_consortia_intermediate_report, :cre_ex_pa_mouse_allele_type, :string
    add_column :new_consortia_intermediate_report, :cre_ex_pa_allele_symbol_superscript_template, :string
    add_column :new_consortia_intermediate_report, :cre_ex_pa_allele_symbol_superscript, :string
    add_column :new_consortia_intermediate_report, :cre_ex_mi_attempt_consortium, :string
    add_column :new_consortia_intermediate_report, :cre_ex_mi_attempt_production_centre, :string
    add_column :new_consortia_intermediate_report, :cre_ex_phenotype_attempt_colony_name, :string
  end

  def self.down
    remove_column :new_intermediate_report, :non_cre_ex_phenotype_attempt_status
    remove_column :new_intermediate_report, :non_cre_ex_phenotype_attempt_registered_date
    remove_column :new_intermediate_report, :non_cre_ex_rederivation_started_date
    remove_column :new_intermediate_report, :non_cre_ex_rederivation_complete_date
    remove_column :new_intermediate_report, :non_cre_ex_cre_excision_started_date
    remove_column :new_intermediate_report, :non_cre_ex_cre_excision_complete_date
    remove_column :new_intermediate_report, :non_cre_ex_phenotyping_started_date
    remove_column :new_intermediate_report, :non_cre_ex_phenotyping_complete_date
    remove_column :new_intermediate_report, :non_cre_ex_phenotype_attempt_aborted_date
    remove_column :new_intermediate_report, :non_cre_ex_pa_mouse_allele_type
    remove_column :new_intermediate_report, :non_cre_ex_pa_allele_symbol_superscript_template
    remove_column :new_intermediate_report, :non_cre_ex_pa_allele_symbol_superscript
    remove_column :new_intermediate_report, :non_cre_ex_mi_attempt_consortium
    remove_column :new_intermediate_report, :non_cre_ex_mi_attempt_production_centre
    remove_column :new_intermediate_report, :non_cre_ex_phenotype_attempt_colony_name
    remove_column :new_intermediate_report, :cre_ex_phenotype_attempt_status
    remove_column :new_intermediate_report, :cre_ex_phenotype_attempt_registered_date
    remove_column :new_intermediate_report, :cre_ex_rederivation_started_date
    remove_column :new_intermediate_report, :cre_ex_rederivation_complete_date
    remove_column :new_intermediate_report, :cre_ex_cre_excision_started_date
    remove_column :new_intermediate_report, :cre_ex_cre_excision_complete_date
    remove_column :new_intermediate_report, :cre_ex_phenotyping_started_date
    remove_column :new_intermediate_report, :cre_ex_phenotyping_complete_date
    remove_column :new_intermediate_report, :cre_ex_phenotype_attempt_aborted_date
    remove_column :new_intermediate_report, :cre_ex_pa_mouse_allele_type
    remove_column :new_intermediate_report, :cre_ex_pa_allele_symbol_superscript_template
    remove_column :new_intermediate_report, :cre_ex_pa_allele_symbol_superscript
    remove_column :new_intermediate_report, :cre_ex_mi_attempt_consortium
    remove_column :new_intermediate_report, :cre_ex_mi_attempt_production_centre
    remove_column :new_intermediate_report, :cre_ex_phenotype_attempt_colony_name

    remove_column :new_gene_intermediate_report, :non_cre_ex_phenotype_attempt_status
    remove_column :new_gene_intermediate_report, :non_cre_ex_phenotype_attempt_registered_date
    remove_column :new_gene_intermediate_report, :non_cre_ex_rederivation_started_date
    remove_column :new_gene_intermediate_report, :non_cre_ex_rederivation_complete_date
    remove_column :new_gene_intermediate_report, :non_cre_ex_cre_excision_started_date
    remove_column :new_gene_intermediate_report, :non_cre_ex_cre_excision_complete_date
    remove_column :new_gene_intermediate_report, :non_cre_ex_phenotyping_started_date
    remove_column :new_gene_intermediate_report, :non_cre_ex_phenotyping_complete_date
    remove_column :new_gene_intermediate_report, :non_cre_ex_phenotype_attempt_aborted_date
    remove_column :new_gene_intermediate_report, :non_cre_ex_pa_mouse_allele_type
    remove_column :new_gene_intermediate_report, :non_cre_ex_pa_allele_symbol_superscript_template
    remove_column :new_gene_intermediate_report, :non_cre_ex_pa_allele_symbol_superscript
    remove_column :new_gene_intermediate_report, :non_cre_ex_mi_attempt_consortium
    remove_column :new_gene_intermediate_report, :non_cre_ex_mi_attempt_production_centre
    remove_column :new_gene_intermediate_report, :non_cre_ex_phenotype_attempt_colony_name
    remove_column :new_gene_intermediate_report, :cre_ex_phenotype_attempt_status
    remove_column :new_gene_intermediate_report, :cre_ex_phenotype_attempt_registered_date
    remove_column :new_gene_intermediate_report, :cre_ex_rederivation_started_date
    remove_column :new_gene_intermediate_report, :cre_ex_rederivation_complete_date
    remove_column :new_gene_intermediate_report, :cre_ex_cre_excision_started_date
    remove_column :new_gene_intermediate_report, :cre_ex_cre_excision_complete_date
    remove_column :new_gene_intermediate_report, :cre_ex_phenotyping_started_date
    remove_column :new_gene_intermediate_report, :cre_ex_phenotyping_complete_date
    remove_column :new_gene_intermediate_report, :cre_ex_phenotype_attempt_aborted_date
    remove_column :new_gene_intermediate_report, :cre_ex_pa_mouse_allele_type
    remove_column :new_gene_intermediate_report, :cre_ex_pa_allele_symbol_superscript_template
    remove_column :new_gene_intermediate_report, :cre_ex_pa_allele_symbol_superscript
    remove_column :new_gene_intermediate_report, :cre_ex_mi_attempt_consortium
    remove_column :new_gene_intermediate_report, :cre_ex_mi_attempt_production_centre
    remove_column :new_gene_intermediate_report, :cre_ex_phenotype_attempt_colony_name

    remove_column :new_consortia_intermediate_report, :non_cre_ex_phenotype_attempt_status
    remove_column :new_consortia_intermediate_report, :non_cre_ex_phenotype_attempt_registered_date
    remove_column :new_consortia_intermediate_report, :non_cre_ex_rederivation_started_date
    remove_column :new_consortia_intermediate_report, :non_cre_ex_rederivation_complete_date
    remove_column :new_consortia_intermediate_report, :non_cre_ex_cre_excision_started_date
    remove_column :new_consortia_intermediate_report, :non_cre_ex_cre_excision_complete_date
    remove_column :new_consortia_intermediate_report, :non_cre_ex_phenotyping_started_date
    remove_column :new_consortia_intermediate_report, :non_cre_ex_phenotyping_complete_date
    remove_column :new_consortia_intermediate_report, :non_cre_ex_phenotype_attempt_aborted_date
    remove_column :new_consortia_intermediate_report, :non_cre_ex_pa_mouse_allele_type
    remove_column :new_consortia_intermediate_report, :non_cre_ex_pa_allele_symbol_superscript_template
    remove_column :new_consortia_intermediate_report, :non_cre_ex_pa_allele_symbol_superscript
    remove_column :new_consortia_intermediate_report, :non_cre_ex_mi_attempt_consortium
    remove_column :new_consortia_intermediate_report, :non_cre_ex_mi_attempt_production_centre
    remove_column :new_consortia_intermediate_report, :non_cre_ex_phenotype_attempt_colony_name
    remove_column :new_consortia_intermediate_report, :cre_ex_phenotype_attempt_status
    remove_column :new_consortia_intermediate_report, :cre_ex_phenotype_attempt_registered_date
    remove_column :new_consortia_intermediate_report, :cre_ex_rederivation_started_date
    remove_column :new_consortia_intermediate_report, :cre_ex_rederivation_complete_date
    remove_column :new_consortia_intermediate_report, :cre_ex_cre_excision_started_date
    remove_column :new_consortia_intermediate_report, :cre_ex_cre_excision_complete_date
    remove_column :new_consortia_intermediate_report, :cre_ex_phenotyping_started_date
    remove_column :new_consortia_intermediate_report, :cre_ex_phenotyping_complete_date
    remove_column :new_consortia_intermediate_report, :cre_ex_phenotype_attempt_aborted_date
    remove_column :new_consortia_intermediate_report, :cre_ex_pa_mouse_allele_type
    remove_column :new_consortia_intermediate_report, :cre_ex_pa_allele_symbol_superscript_template
    remove_column :new_consortia_intermediate_report, :cre_ex_pa_allele_symbol_superscript
    remove_column :new_consortia_intermediate_report, :cre_ex_mi_attempt_consortium
    remove_column :new_consortia_intermediate_report, :cre_ex_mi_attempt_production_centre
    remove_column :new_consortia_intermediate_report, :cre_ex_phenotype_attempt_colony_name
  end
end
