class IntermediateReportSummaryByCentre < ActiveRecord::Base
  self.table_name = :intermediate_report_summary_by_centre

  acts_as_reportable

  class << self

    def select_sql(category = 'es cell', approach = 'all', allele_type= nil)

     select_data = {['es cell','all'] => {'all' => es_cell_sql, 'allele_based' => es_cell_sql},
#                    ['es cell','micro injection'] => {'all' => ?, 'allele_based' => ?},
#                    ['es cell','mouse allele modification'] => {'all' => ?, 'allele_based' => ?},
                    ['crispr','all']  => {'all' => crispr_sql, 'allele_based' => crispr_sql},
#                    ['crispr','micro injection'] => {'all' => ?, 'allele_based' => ?},
#                    ['crispr','mouse allele modification'] => {'all' => ?, 'allele_based' => ?},
                    ['all','all']     => {'all' => es_cell_and_crispr_sql, 'allele_based' => es_cell_and_crispr_sql},
#                    ['all','micro injection'] => {'all' => ?, 'allele_based' => ?},
#                    ['all','mouse allele modification'] => {'all' => ?, 'allele_based' => ?}
                   }

     if !allele_type.nil?
       return select_data[[category,'all']]['allele_based']
     else
       return select_data[[category,'all']]['all']
     end
    end


    def es_cell_and_crispr_sql
      <<-EOF
        SELECT #{select_fields}
        FROM (SELECT DISTINCT mi_plans.gene_id, mi_plans.production_centre_id FROM mi_plans) distinct_gene_centres
          JOIN centres ON centres.id = distinct_gene_centres.consortium_id
          JOIN genes ON genes.id = distinct_gene_centres.gene_id
          LEFT JOIN (SELECT * FROM intermediate_report_summary_by_centre WHERE intermediate_report_summary_by_centre.catagory = 'all' AND intermediate_report_summary_by_centre.approach = 'plan') AS plan_summary ON plan_summary.gene = genes.marker_symbol AND plan_summary.production_centre = centres.name
          LEFT JOIN (SELECT * FROM intermediate_report_summary_by_centre WHERE intermediate_report_summary_by_centre.catagory = 'all' AND intermediate_report_summary_by_centre.approach = 'micro-injection') AS mi_production_summary ON mi_production_summary.gene = genes.marker_symbol AND mi_production_summary.production_centre = centres.name
          LEFT JOIN (SELECT * FROM intermediate_report_summary_by_centre WHERE intermediate_report_summary_by_centre.catagory = 'all' AND intermediate_report_summary_by_centre.approach = 'mouse allele modification') AS allele_mod_production_summary ON allele_mod_production_summary.gene = genes.marker_symbol AND allele_mod_production_summary.production_centre = centres.name
          LEFT JOIN (SELECT * FROM intermediate_report_summary_by_centre WHERE intermediate_report_summary_by_centre.catagory = 'all' AND intermediate_report_summary_by_centre.approach = 'all') AS phenotyping_production_summary ON phenotyping_production_summary.gene = genes.marker_symbol AND phenotyping_production_summary.production_centre = centres.name
        WHERE phenotyping_production_summary.phenotyping_status IS NOT NULL OR
              allele_mod_production_summary.mouse_allele_mod_status IS NOT NULL OR
              mi_production_summary.mi_attempt_status IS NOT NULL OR
              plan_summary.mi_plan_status IS NOT NULL
      EOF
    end

    def es_cell_sql
      <<-EOF
        SELECT #{select_fields}
        FROM (SELECT DISTINCT mi_plans.gene_id, mi_plans.production_centre_id FROM mi_plans) distinct_gene_centres
          JOIN centres ON centres.id = distinct_gene_centres.consortium_id
          JOIN genes ON genes.id = distinct_gene_centres.gene_id
          LEFT JOIN (SELECT * FROM intermediate_report_summary_by_centre WHERE intermediate_report_summary_by_centre.catagory = 'es cell' AND intermediate_report_summary_by_centre.approach = 'plan') AS plan_summary ON plan_summary.gene = genes.marker_symbol AND plan_summary.production_centre = centres.name
          LEFT JOIN (SELECT * FROM intermediate_report_summary_by_centre WHERE intermediate_report_summary_by_centre.catagory = 'es cell' AND intermediate_report_summary_by_centre.approach = 'micro-injection') AS mi_production_summary ON mi_production_summary.gene = genes.marker_symbol AND mi_production_summary.production_centre = centres.name
          LEFT JOIN (SELECT * FROM intermediate_report_summary_by_centre WHERE intermediate_report_summary_by_centre.catagory = 'es cell' AND intermediate_report_summary_by_centre.approach = 'mouse allele modification') AS allele_mod_production_summary ON allele_mod_production_summary.gene = genes.marker_symbol AND allele_mod_production_summary.production_centre = centres.name
          LEFT JOIN (SELECT * FROM intermediate_report_summary_by_centre WHERE intermediate_report_summary_by_centre.catagory = 'es cell' AND intermediate_report_summary_by_centre.approach = 'all') AS phenotyping_production_summary ON phenotyping_production_summary.gene = genes.marker_symbol AND phenotyping_production_summary.production_centre = centres.name
        WHERE phenotyping_production_summary.phenotyping_status IS NOT NULL OR
              allele_mod_production_summary.mouse_allele_mod_status IS NOT NULL OR
              mi_production_summary.mi_attempt_status IS NOT NULL OR
              plan_summary.mi_plan_status IS NOT NULL
      EOF
    end

    def crispr_sql
      <<-EOF
        SELECT #{select_fields}
        FROM (SELECT DISTINCT mi_plans.gene_id, mi_plans.production_centre_id FROM mi_plans) distinct_gene_centres
          JOIN centres ON centres.id = distinct_gene_centres.consortium_id
          JOIN genes ON genes.id = distinct_gene_centres.gene_id
          LEFT JOIN (SELECT * FROM intermediate_report_summary_by_centre WHERE intermediate_report_summary_by_centre.catagory = 'crispr' AND intermediate_report_summary_by_centre.approach = 'plan') AS plan_summary ON plan_summary.gene = genes.marker_symbol AND plan_summary.production_centre = centres.name
          LEFT JOIN (SELECT * FROM intermediate_report_summary_by_centre WHERE intermediate_report_summary_by_centre.catagory = 'crispr' AND intermediate_report_summary_by_centre.approach = 'micro-injection') AS mi_production_summary ON mi_production_summary.gene = genes.marker_symbol AND mi_production_summary.production_centre = centres.name
          LEFT JOIN (SELECT * FROM intermediate_report_summary_by_centre WHERE intermediate_report_summary_by_centre.catagory = 'crispr' AND intermediate_report_summary_by_centre.approach = 'mouse allele modification') AS allele_mod_production_summary ON allele_mod_production_summary.gene = genes.marker_symbol AND allele_mod_production_summary.production_centre = centres.name
          LEFT JOIN (SELECT * FROM intermediate_report_summary_by_centre WHERE intermediate_report_summary_by_centre.catagory = 'crispr' AND intermediate_report_summary_by_centre.approach = 'all') AS phenotyping_production_summary ON phenotyping_production_summary.gene = genes.marker_symbol AND phenotyping_production_summary.production_centre = centres.name
        WHERE phenotyping_production_summary.phenotyping_status IS NOT NULL OR
              allele_mod_production_summary.mouse_allele_mod_status IS NOT NULL OR
              mi_production_summary.mi_attempt_status IS NOT NULL OR
              plan_summary.mi_plan_status IS NOT NULL
      EOF
    end

    def select_fields
      <<-EOF
           plan_summary.mi_plan_id,
           mi_production_summary.mi_attempt_id,
           allele_mod_production_summary.modified_mouse_allele_mod_id,
           allele_mod_production_summary.mouse_allele_mod_id,
           phenotyping_production_summary.phenotyping_production_id,
           centres.name AS production_centre,
           genes.marker_symbol AS gene,
           plan_summary.mgi_accession_id,
           mi_production_summary.mi_attempt_external_ref,
           mi_production_summary.mi_attempt_colony_name,
           allele_mod_production_summary.mouse_allele_mod_colony_name,
           phenotyping_production_summary.phenotyping_production_colony_name,

           CASE WHEN phenotyping_production_summary.phenotyping_status = 'Phenotype Production Aborted' AND (allele_mod_production_summary.mouse_allele_mod_status IS NULL OR allele_mod_production_summary.mouse_allele_mod_status = 'Mouse Allele Modification Aborted')
                THEN 'Phenotype Attempt Aborted'
                WHEN phenotyping_production_summary.phenotyping_status IS NOT NULL THEN phenotyping_production_summary.phenotyping_status
                WHEN allele_mod_production_summary.mouse_allele_mod_status IS NOT NULL THEN allele_mod_production_summary.mouse_allele_mod_status
                WHEN mi_production_summary.mi_attempt_status IS NOT NULL THEN mi_production_summary.mi_attempt_status
                WHEN plan_summary.mi_plan_status IS NOT NULL THEN plan_summary.mi_plan_status
           END AS overall_status,

           plan_summary.mi_plan_status,
           plan_summary.assigned_date,
           plan_summary.assigned_es_cell_qc_in_progress_date,
           plan_summary.assigned_es_cell_qc_complete_date,
           plan_summary.aborted_es_cell_qc_failed_date,
           mi_production_summary.mi_attempt_status,
           mi_production_summary.micro_injection_aborted_date,
           mi_production_summary.micro_injection_in_progress_date,
           mi_production_summary.chimeras_obtained_date,
           mi_production_summary.founder_obtained_date,
           mi_production_summary.genotype_confirmed_date,
           allele_mod_production_summary.mouse_allele_mod_status,
           allele_mod_production_summary.mouse_allele_mod_registered_date,
           allele_mod_production_summary.rederivation_started_date,
           allele_mod_production_summary.rederivation_complete_date,
           allele_mod_production_summary.cre_excision_started_date,
           allele_mod_production_summary.cre_excision_complete_date,
           phenotyping_production_summary.phenotyping_status,
           phenotyping_production_summary.phenotyping_registered_date,
           phenotyping_production_summary.phenotyping_rederivation_started_date,
           phenotyping_production_summary.phenotyping_rederivation_complete_date,
           phenotyping_production_summary.phenotyping_experiments_started_date,
           phenotyping_production_summary.phenotyping_started_date,
           phenotyping_production_summary.phenotyping_complete_date,
           phenotyping_production_summary.phenotype_attempt_aborted_date
      EOF
    end
  end
end

# == Schema Information
#
# Table name: intermediate_report_summary_by_centre
#
#  id                                     :integer          not null, primary key
#  catagory                               :string(255)      not null
#  approach                               :string(255)      not null
#  allele_type                            :string(255)      not null
#  mi_plan_id                             :integer
#  mi_attempt_id                          :integer
#  modified_mouse_allele_mod_id           :integer
#  mouse_allele_mod_id                    :integer
#  phenotyping_production_id              :integer
#  production_centre                      :string(255)
#  gene                                   :string(255)
#  mgi_accession_id                       :string(255)
#  mi_attempt_external_ref                :string(255)
#  mi_attempt_colony_name                 :string(255)
#  mouse_allele_mod_colony_name           :string(255)
#  phenotyping_production_colony_name     :string(255)
#  mi_plan_status                         :string(255)
#  gene_interest_date                     :date
#  assigned_date                          :date
#  assigned_es_cell_qc_in_progress_date   :date
#  assigned_es_cell_qc_complete_date      :date
#  aborted_es_cell_qc_failed_date         :date
#  mi_attempt_status                      :string(255)
#  micro_injection_aborted_date           :date
#  micro_injection_in_progress_date       :date
#  chimeras_obtained_date                 :date
#  founder_obtained_date                  :date
#  genotype_confirmed_date                :date
#  mouse_allele_mod_status                :string(255)
#  mouse_allele_mod_registered_date       :date
#  rederivation_started_date              :date
#  rederivation_complete_date             :date
#  cre_excision_started_date              :date
#  cre_excision_complete_date             :date
#  phenotyping_status                     :string(255)
#  phenotyping_registered_date            :date
#  phenotyping_rederivation_started_date  :date
#  phenotyping_rederivation_complete_date :date
#  phenotyping_experiments_started_date   :date
#  phenotyping_started_date               :date
#  phenotyping_complete_date              :date
#  phenotype_attempt_aborted_date         :date
#  created_at                             :date
#
# Indexes
#
#  irscen_allele_type              (allele_type)
#  irscen_approach                 (approach)
#  irscen_catagory                 (catagory)
#  irscen_mi_attempts              (mi_attempt_id)
#  irscen_mi_plans                 (mi_plan_id)
#  irscen_mouse_allele_mods        (mouse_allele_mod_id)
#  irscen_phenotyping_productions  (phenotyping_production_id)
#
