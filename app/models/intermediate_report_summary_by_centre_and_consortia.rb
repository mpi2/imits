class IntermediateReportSummaryByCentreAndConsortia < ActiveRecord::Base
  self.table_name = :intermediate_report_summary_by_centre_and_consortia

  acts_as_reportable

  belongs_to :mi_plans
  belongs_to :mi_attmepts
  belongs_to :mouse_allele_mod
  belongs_to :phenotyping_production


  class << self

    def plan_summary(options)
      where_clause = {'category' => options.has_key?('category') ? options['category'] : 'es cell'}
      generate_sql(where_clause, {'mi_production' => false, 'allele_mod_production' => false, 'phenotyping' => false})
    end

    def mi_production_summary(options)
      where_clause = {'category' => options.has_key?('category') ? options['category'] : 'es cell'}
      generate_sql(where_clause, {'mi_production' => true, 'allele_mod_production' => false, 'phenotyping' => false})
    end

    def mi_phenotyping_summary(options)
      where_clause = {'category' => options.has_key?('category') ? options['category'] : 'es cell', 'phenotyping_approach' => 'micro-injection'}
      generate_sql(where_clause, {'mi_production' => false, 'allele_mod_production' => false, 'phenotyping' => true})
    end

    def mam_production_summary(options)
      where_clause = {'category' => options.has_key?('category') ? options['category'] : 'es cell'}
      generate_sql(where_clause, {'mi_production' => false, 'allele_mod_production' => true, 'phenotyping' => false})
    end

    def mam_phenotyping_summary(options)
      where_clause = {'category' => options.has_key?('category') ? options['category'] : 'es cell', 'phenotyping_approach' => 'mouse allele modification'}
      generate_sql(where_clause, {'mi_production' => false, 'allele_mod_production' => false, 'phenotyping' => true})
    end

    def phenotyping_summary_include_everything(options)
      where_clause = {'category' => options.has_key?('category') ? options['category'] : 'es cell', 'phenotyping_approach' => nil}
      generate_sql(where_clause, {'mi_production' => false, 'allele_mod_production' => false, 'phenotyping' => true})
    end

    def generate_sql( where_clauses = {}, display = {})
      display['plan'] = true
      display['mi_production'] = true if !display.has_key?('mi_production')
      display['allele_mod_production'] = true if !display.has_key?('allele_mod_production')
      display['phenotyping'] = true if !display.has_key?('phenotyping')

      where_clauses['category'] = 'es cell' if !where_clauses.has_key?('category')

      if !where_clauses.has_key?('phenotyping_approach')
        where_clauses['phenotyping_approach'] = 'all'
        if !display.has_key?('allele_mod_production') || !display.has_key?('mi_production')
          if display.has_key?('mi_production')
            where_clauses['phenotyping_approach'] = 'micro-injection'
          elsif display.has_key?('allele_mod_production')
            where_clauses['phenotyping_approach'] = 'mouse allele modification'
          end
        end
      end

      sql = <<-EOF
        SELECT #{select_fields(display)}
        FROM (SELECT *
               FROM intermediate_report_summary_by_centre_and_consortia
               WHERE intermediate_report_summary_by_centre_and_consortia.catagory = '#{where_clauses['category']}' AND intermediate_report_summary_by_centre_and_consortia.approach = 'plan'
             ) AS plan_summary
      EOF

      if display.has_key?('mi_production') && display['mi_production'] == true
        sql += <<-EOF
          LEFT JOIN (SELECT *
                     FROM intermediate_report_summary_by_centre_and_consortia
                     WHERE intermediate_report_summary_by_centre_and_consortia.catagory = '#{where_clauses['category']}' AND intermediate_report_summary_by_centre_and_consortia.approach = 'micro-injection'
                    ) AS mi_production_summary ON mi_production_summary.gene = plan_summary.gene AND mi_production_summary.consortium = plan_summary.consortium
        EOF
      end

      if display.has_key?('allele_mod_production') && display['allele_mod_production'] == true
        sql += <<-EOF
          LEFT JOIN (SELECT *
                     FROM intermediate_report_summary_by_centre_and_consortia
                     WHERE intermediate_report_summary_by_centre_and_consortia.catagory = '#{where_clauses['category']}' AND intermediate_report_summary_by_centre_and_consortia.approach = 'mouse allele modification'
                    ) AS allele_mod_production_summary ON allele_mod_production_summary.gene = plan_summary.gene AND allele_mod_production_summary.consortium = plan_summary.consortium
        EOF
      end

      if display.has_key?('phenotyping') && display['phenotyping'] == true
        sql += <<-EOF
          LEFT JOIN (SELECT *
                     FROM intermediate_report_summary_by_centre_and_consortia
                     WHERE intermediate_report_summary_by_centre_and_consortia.catagory = '#{where_clauses['category']}' #{!where_clauses['phenotyping_approach'].nil? ? "AND intermediate_report_summary_by_centre_and_consortia.approach = '#{where_clauses['phenotyping_approach']}'" : ''}
                    ) AS phenotyping_production_summary ON phenotyping_production_summary.gene = plan_summary.gene AND phenotyping_production_summary.consortium = plan_summary.consortium
        EOF
      end

      return sql
    end

    def select_fields(display = {'mi_production' => true, 'allele_mod_production' => true, 'phenotyping' => true})
      display['plan'] = true
      #confiuration of fields that should be returned
      sql = ''
      puts "HELLO THERE #{display.has_key?('plan') && display['plan'] == true}"
      if display.has_key?('plan') && display['plan'] == true
        sql += <<-EOF
               plan_summary.mi_plan_id,
               plan_summary.consortium,
               plan_summary.production_centre,
               plan_summary.gene,
               plan_summary.mgi_accession_id,
               plan_summary.mi_plan_status,
               plan_summary.gene_interest_date,
               plan_summary.assigned_date,
               plan_summary.assigned_es_cell_qc_in_progress_date,
               plan_summary.assigned_es_cell_qc_complete_date,
               plan_summary.aborted_es_cell_qc_failed_date
        EOF
      end

      if display.has_key?('mi_production') && display['mi_production'] == true
        sql += <<-EOF
               ,mi_production_summary.mi_attempt_id,
               mi_production_summary.mi_attempt_external_ref,
               mi_production_summary.mi_attempt_colony_name,
               mi_production_summary.mi_attempt_status,
               mi_production_summary.micro_injection_aborted_date,
               mi_production_summary.micro_injection_in_progress_date,
               mi_production_summary.chimeras_obtained_date,
               mi_production_summary.founder_obtained_date,
               mi_production_summary.genotype_confirmed_date
        EOF
      end

      if display.has_key?('allele_mod_production') && display['allele_mod_production'] == true
        sql += <<-EOF
               ,allele_mod_production_summary.modified_mouse_allele_mod_id,
               allele_mod_production_summary.mouse_allele_mod_id,
               allele_mod_production_summary.mouse_allele_mod_colony_name,
               allele_mod_production_summary.mouse_allele_mod_status,
               allele_mod_production_summary.mouse_allele_mod_registered_date,
               allele_mod_production_summary.rederivation_started_date,
               allele_mod_production_summary.rederivation_complete_date,
               allele_mod_production_summary.cre_excision_started_date,
               allele_mod_production_summary.cre_excision_complete_date
        EOF
      end

      if display.has_key?('phenotyping') && display['phenotyping'] == true
        sql += <<-EOF
               ,phenotyping_production_summary.phenotyping_production_id,
               phenotyping_production_summary.phenotyping_production_colony_name,
               phenotyping_production_summary.phenotyping_status,
               phenotyping_production_summary.phenotype_attempt_registered_date,
               phenotyping_production_summary.phenotyping_experiments_started_date,
               phenotyping_production_summary.phenotyping_started_date,
               phenotyping_production_summary.phenotyping_complete_date,
               phenotyping_production_summary.phenotype_attempt_aborted_date,
               phenotyping_production_summary.approach AS phenotyping_approach
        EOF
      end

      return sql
    end

  end

end

# == Schema Information
#
# Table name: intermediate_report_summary_by_centre_and_consortia
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
#  production_centre                    :string(255)
#  gene                                 :string(255)
#  mgi_accession_id                     :string(255)
#  mi_attempt_external_ref              :string(255)
#  mi_attempt_colony_name               :string(255)
#  mouse_allele_mod_colony_name         :string(255)
#  phenotyping_production_colony_name   :string(255)
#  mi_plan_status                       :string(255)
#  gene_interest_date                   :date
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
#  irscc_allele_type  (allele_type)
#  irscc_approach     (approach)
#  irscc_catagory     (catagory)
#
