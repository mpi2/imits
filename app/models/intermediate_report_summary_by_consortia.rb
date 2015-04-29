class IntermediateReportSummaryByConsortia < ActiveRecord::Base
  self.table_name = :intermediate_report_summary_by_consortia

  acts_as_reportable

  belongs_to :mi_plans
  belongs_to :mi_attmepts
  belongs_to :mouse_allele_mod
  belongs_to :phenotyping_production


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

     if allele_type.nil?
       return select_data[[category,'all']]['allele_based']
     else
       return select_data[[category,'all']]['all']
     end
    end


    def es_cell_and_crispr_sql
      <<-EOF
        SELECT #{select_fields}
        FROM      (SELECT * FROM intermediate_report_summary_by_consortia WHERE intermediate_report_summary_by_consortia.catagory = 'all' AND intermediate_report_summary_by_consortia.approach = 'plan') AS plan_summary
        LEFT JOIN (SELECT * FROM intermediate_report_summary_by_consortia WHERE intermediate_report_summary_by_consortia.catagory = 'all' AND intermediate_report_summary_by_consortia.approach = 'micro-injection') AS mi_production_summary ON mi_production_summary.gene = plan_summary.gene AND mi_production_summary.consortium = plan_summary.consortium
        LEFT JOIN (SELECT * FROM intermediate_report_summary_by_consortia WHERE intermediate_report_summary_by_consortia.catagory = 'all' AND intermediate_report_summary_by_consortia.approach = 'mouse allele modification') AS allele_mod_production_summary ON allele_mod_production_summary.gene = plan_summary.gene AND allele_mod_production_summary.consortium = plan_summary.consortium
        LEFT JOIN (SELECT * FROM intermediate_report_summary_by_consortia WHERE intermediate_report_summary_by_consortia.catagory = 'all' AND intermediate_report_summary_by_consortia.approach = 'all') AS phenotyping_production_summary ON phenotyping_production_summary.gene = plan_summary.gene AND phenotyping_production_summary.consortium = plan_summary.consortium
      EOF
    end

    def es_cell_sql
      <<-EOF
        SELECT #{select_fields}
        FROM      (SELECT * FROM intermediate_report_summary_by_consortia WHERE intermediate_report_summary_by_consortia.catagory = 'es cell' AND intermediate_report_summary_by_consortia.approach = 'plan') AS plan_summary
        LEFT JOIN (SELECT * FROM intermediate_report_summary_by_consortia WHERE intermediate_report_summary_by_consortia.catagory = 'es cell' AND intermediate_report_summary_by_consortia.approach = 'micro-injection') AS mi_production_summary ON mi_production_summary.gene = plan_summary.gene AND mi_production_summary.consortium = plan_summary.consortium
        LEFT JOIN (SELECT * FROM intermediate_report_summary_by_consortia WHERE intermediate_report_summary_by_consortia.catagory = 'es cell' AND intermediate_report_summary_by_consortia.approach = 'mouse allele modification') AS allele_mod_production_summary ON allele_mod_production_summary.gene = plan_summary.gene AND allele_mod_production_summary.consortium = plan_summary.consortium
        LEFT JOIN (SELECT * FROM intermediate_report_summary_by_consortia WHERE intermediate_report_summary_by_consortia.catagory = 'es cell' AND intermediate_report_summary_by_consortia.approach = 'all') AS phenotyping_production_summary ON phenotyping_production_summary.gene = plan_summary.gene AND phenotyping_production_summary.consortium = plan_summary.consortium
      EOF
    end

    def crispr_sql
      <<-EOF
        SELECT #{select_fields}
        FROM      (SELECT * FROM intermediate_report_summary_by_consortia WHERE intermediate_report_summary_by_consortia.catagory = 'crispr' AND intermediate_report_summary_by_consortia.approach = 'plan') AS plan_summary
        LEFT JOIN (SELECT * FROM intermediate_report_summary_by_consortia WHERE intermediate_report_summary_by_consortia.catagory = 'crispr' AND intermediate_report_summary_by_consortia.approach = 'micro-injection') AS mi_production_summary ON mi_production_summary.gene = plan_summary.gene AND mi_production_summary.consortium = plan_summary.consortium
        LEFT JOIN (SELECT * FROM intermediate_report_summary_by_consortia WHERE intermediate_report_summary_by_consortia.catagory = 'crispr' AND intermediate_report_summary_by_consortia.approach = 'mouse allele modification') AS allele_mod_production_summary ON allele_mod_production_summary.gene = plan_summary.gene AND allele_mod_production_summary.consortium = plan_summary.consortium
        LEFT JOIN (SELECT * FROM intermediate_report_summary_by_consortia WHERE intermediate_report_summary_by_consortia.catagory = 'crispr' AND intermediate_report_summary_by_consortia.approach = 'all') AS phenotyping_production_summary ON phenotyping_production_summary.gene = plan_summary.gene AND phenotyping_production_summary.consortium = plan_summary.consortium
      EOF
    end

    def select_fields
      <<-EOF
           plan_summary.mi_plan_id,
           mi_production_summary.mi_attempt_id,
           allele_mod_production_summary.modified_mouse_allele_mod_id,
           allele_mod_production_summary.mouse_allele_mod_id,
           phenotyping_production_summary.phenotyping_production_id,
           plan_summary.consortium,
           plan_summary.gene,
           plan_summary.mgi_accession_id,
           mi_production_summary.mi_attempt_external_ref,
           mi_production_summary.mi_attempt_colony_name,
           allele_mod_production_summary.mouse_allele_mod_colony_name,
           phenotyping_production_summary.phenotyping_production_colony_name,
           plan_summary.mi_plan_status,
           plan_summary.gene_interest_date,
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
           phenotyping_production_summary.phenotype_attempt_registered_date,
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
# Table name: intermediate_report_summary_by_consortia
#
#  id                                   :integer          not null, primary key
#  catagory                             :string(255)      not null
#  approach                             :string(255)      not null
#  allele_type                          :string(255)      not null
#  mi_plan_id                           :integer
#  mi_attempt_id                        :integer
#  modified_mouse_allele_mod_id         :integer
#  mouse_allele_mod_id                  :integer
#  phenotyping_production_id            :integer
#  consortium                           :string(255)
#  gene                                 :string(255)
#  mgi_accession_id                     :string(255)
#  gene_interest_date                   :date
#  mi_attempt_external_ref              :string(255)
#  mi_attempt_colony_name               :string(255)
#  mouse_allele_mod_colony_name         :string(255)
#  phenotyping_production_colony_name   :string(255)
#  mi_plan_status                       :string(255)
#  assigned_date                        :date
#  assigned_es_cell_qc_in_progress_date :date
#  assigned_es_cell_qc_complete_date    :date
#  aborted_es_cell_qc_failed_date       :date
#  mi_attempt_status                    :string(255)
#  micro_injection_aborted_date         :date
#  micro_injection_in_progress_date     :date
#  chimeras_obtained_date               :date
#  founder_obtained_date                :date
#  genotype_confirmed_date              :date
#  mouse_allele_mod_status              :string(255)
#  mouse_allele_mod_registered_date     :date
#  rederivation_started_date            :date
#  rederivation_complete_date           :date
#  cre_excision_started_date            :date
#  cre_excision_complete_date           :date
#  phenotyping_status                   :string(255)
#  phenotype_attempt_registered_date    :date
#  phenotyping_experiments_started_date :date
#  phenotyping_started_date             :date
#  phenotyping_complete_date            :date
#  phenotype_attempt_aborted_date       :date
#  created_at                           :date
#
# Indexes
#
#  irsc_allele_type  (allele_type)
#  irsc_approach     (approach)
#  irsc_catagory     (catagory)
#
