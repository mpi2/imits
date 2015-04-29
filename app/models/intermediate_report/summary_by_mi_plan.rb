module IntermediateReport::SummaryByMiPlan
  class Generate < IntermediateReport::Base

    def to_s
      "#<IntermediateReportSummaryByConsortia::Generate size: #{size}>"
    end

    ##
    ## Class methods
    ##

    class << self
      def table
        "intermediate_report_summary_by_mi_plan"
      end

    def report_sql

      mouse_pipelines = {'micro-injection' => 'false',
                         'mouse allele modification' => 'true',
                         'all' => ''}
      experiment_types = { 'all' => ''}
#      allele_type = {'a' => '',
#                    'e' => '',
#                    '' => '',
#                    'b' => '',
#                    'c' => '',
#                    'e.1' => '',
#                    '.1' => '',
#                    'd' => '',
#                    'ALL' => ''}
      super(experiment_types, mouse_pipelines)
    end

      def experiment_report_logic(experiment_type = nil, plan_condition = nil)
        return []
      end

      def production_sql
        sql = <<-EOF
                  SELECT mi_attempts.id AS mi_attempt_id, NULL AS mouse_allele_mods_id, mi_attempts.mi_plan_id AS mi_plan_id,
                    mi_attempt_statuses.name AS mi_attempt_status,  mi_attempt_status_stamps.created_at AS mi_attempt_status_date, NULL AS mouse_allele_mod_status, NULL AS mouse_allele_mod_status_date,
                    mi_attempt_statuses.name AS production_status, mi_attempt_statuses.order_by AS production_status_order, mi_attempt_status_stamps.created_at AS production_status_order_status_stamp_created_at, false AS allele_modification
                  FROM mi_attempts
                    JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
                    JOIN mi_attempt_status_stamps ON mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id AND mi_attempt_status_stamps.status_id = mi_attempts.status_id
                  UNION

                  SELECT NULL AS mi_attempt_id, mouse_allele_mods.id AS mouse_allele_mods_id, mouse_allele_mods.mi_plan_id AS mi_plan_id,
                    NULL AS mi_attempt_status, NULL AS mi_attempt_status_date, mouse_allele_mod_statuses.name AS mouse_allele_mod_status, mouse_allele_mod_status_stamps.created_at AS mouse_allele_mod_status_date,
                    mouse_allele_mod_statuses.name AS production_status, mouse_allele_mod_statuses.order_by AS production_status_order, mouse_allele_mod_status_stamps.created_at AS production_status_order_status_stamp_created_at, true AS allele_modification
                  FROM mouse_allele_mods
                    JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
                    JOIN mouse_allele_mod_status_stamps ON mouse_allele_mod_status_stamps.mouse_allele_mod_id = mouse_allele_mods.id AND mouse_allele_mod_status_stamps.status_id = mouse_allele_mods.status_id
                EOF
        return sql
      end

      def best_production_sql
         # Expected to be placed inside a WITH statement which already contains the temporary tables filtered_production.
         sql = <<-EOF
            best_production_for_mi_plan AS (
            SELECT
              mi_plans.id AS mi_plan_id,
              filtered_production.production_status_order AS order_by,
              filtered_production.mi_attempt_status,
              filtered_production.mi_attempt_status_date,
              filtered_production.mouse_allele_mod_status,
              filtered_production.mouse_allele_mod_status_date,
              filtered_production.production_status AS production_status,
              filtered_production.mi_attempt_id as mi_attempt_id,
              filtered_production.mouse_allele_mods_id as mouse_allele_mods_id
            FROM mi_plans
              JOIN filtered_production ON mi_plans.id = filtered_production.mi_plan_id
            ORDER BY
              mi_plans.id,
              filtered_production.production_status_order DESC,
              filtered_production.production_status_order_status_stamp_created_at ASC
          ),

          att AS (
            SELECT
              best_production_for_mi_plan.mi_plan_id,
              best_production_for_mi_plan.order_by,
              best_production_for_mi_plan.mi_attempt_status,
              best_production_for_mi_plan.mi_attempt_status_date,
              best_production_for_mi_plan.mouse_allele_mod_status,
              best_production_for_mi_plan.mouse_allele_mod_status_date,
              first_value(best_production_for_mi_plan.mi_attempt_id) OVER (PARTITION BY best_production_for_mi_plan.mi_plan_id) AS mi_attempt_id,
              first_value(best_production_for_mi_plan.mouse_allele_mods_id) OVER (PARTITION BY best_production_for_mi_plan.mi_plan_id) AS mouse_allele_mod_id
            FROM best_production_for_mi_plan
          ),

          top_production AS (
            SELECT att.mi_plan_id, att.mi_attempt_id AS mi_attempt_id, att.mouse_allele_mod_id AS mouse_allele_mod_id,
                   SUM(CASE WHEN mi_attempt_status = 'Micro-injection aborted' THEN 1 ELSE 0 END) AS mi_aborted_count,
                   max(CASE WHEN mi_attempt_status = 'Micro-injection aborted' THEN mi_attempt_status_date ELSE NULL END ) AS mi_aborted_max_date,
                   SUM(CASE WHEN mouse_allele_mod_status = 'Micro-injection aborted' THEN 1 ELSE 0 END) AS allele_mod_aborted_count,
                   max(CASE WHEN mouse_allele_mod_status = 'Micro-injection aborted' THEN mouse_allele_mod_status_date ELSE NULL END ) AS allele_mod_aborted_max_date
            FROM att
            GROUP BY att.mi_plan_id, att.mi_attempt_id, att.mouse_allele_mod_id
          )
        EOF
        return sql
      end

      def best_phenotyping_sql()
        sql = <<-EOF
                  phenotyping_productions_grouped AS (
                    SELECT
                      phenotyping_productions.mi_plan_id AS mi_plan_id,
                      phenotyping_production_statuses.order_by,
                      first_value(phenotyping_productions.id) OVER (PARTITION BY phenotyping_productions.mi_plan_id) AS phenotyping_production_id
                    FROM phenotyping_productions
                      JOIN phenotyping_production_statuses ON phenotyping_production_statuses.id = phenotyping_productions.status_id
                  ),

                  top_phenotyping_production AS (
                    SELECT DISTINCT phenotyping_productions_grouped.mi_plan_id, phenotyping_productions_grouped.phenotyping_production_id
                    FROM phenotyping_productions_grouped
                  )

                EOF
        return sql
      end

      def best_production_report_sql(experiment_type, approach, plan_condition = nil , production_condition = nil)
        <<-EOF
          --
          WITH filtered_production AS (SELECT * FROM (#{production_sql}) AS production #{!production_condition.blank? ? "WHERE production.allele_modification = #{production_condition}" : ""} ), #{best_production_sql}, #{best_phenotyping_sql}

          SELECT
              CASE WHEN mi_plans.mutagenesis_via_crispr_cas9 = true THEN 'crispr' ELSE 'es cell' END AS catagory,
              '#{approach}' AS approach,
              'All' AS allele_type,

              genes.marker_symbol AS gene,
              genes.mgi_accession_id AS mgi_accession_id,
              consortia.name AS consortium,
              centres.name AS production_centre,

              mi_plan_priorities.name AS priority,
              mi_plan_sub_projects.name AS sub_project,

              mi_plans.id AS mi_plan_id,
              assigned.created_at::date AS assigned_date,
              es_qc_in_progress.created_at::date AS es_qc_in_progress_date,
              es_qc_complete.created_at::date AS es_qc_complete_date,
              es_qc_fail.created_at::date AS es_qc_fail_date,

              mi_plan_statuses.name AS mi_plan_status,
              mi_attempt_statuses.name AS mi_attempt_status,
              mouse_allele_mod_statuses.name AS mouse_allele_mod_status,
              phenotyping_production_statuses.name AS phenotyping_status,

              mi_attempts.id AS mi_attempt_id,
              in_progress_stamps.created_at::date AS micro_injection_in_progress_date,
              chimearic_stamps.created_at::date AS chimeras_obtained_date,
              gc_stamps.created_at::date AS genotype_confirmed_date,
              aborted_stamps.created_at::date AS micro_injection_aborted_date,

              mouse_allele_mods.id AS mouse_allele_mod_id,
              mam_registered_statuses.created_at::date AS mouse_allele_mod_registered_date,
              mam_re_started_statuses.created_at::date AS rederivation_started_date,
              mam_re_complete_statuses.created_at::date AS rederivation_complete_date,
              mam_cre_started_statuses.created_at::date AS cre_excision_started_date,
              mam_cre_complete_statuses.created_at::date AS cre_excision_complete_date,
              mam_aborted_statuses.created_at::date as phenotype_attempt_aborted_date,

              phenotyping_productions.id AS phenotyping_production_id,
              pp_registered_statuses.created_at::date AS phenotyping_registered_date,
              pp_re_started_statuses.created_at::date AS phenotyping_rederivation_started_date,
              pp_re_complete_statuses.created_at::date AS phenotyping_rederivation_complete_date,
              pp_started_statuses.created_at::date AS phenotyping_started_date,
              phenotyping_productions.phenotyping_experiments_started::date AS phenotyping_experiments_started_date,
              pp_complete_statuses.created_at::date AS phenotyping_complete_date,
              pp_aborted_statuses.created_at::date AS phenotype_attempt_aborted_date,

              mi_attempts.external_ref AS mi_attempt_colony_name,
              CASE WHEN mouse_allele_mods IS NOT NULL THEN mi_attempts.external_ref ELSE NULL END AS modified_mouse_line_colony_name,
              mouse_allele_mod_colony.name AS mouse_line_colony_name,
              phenotyping_productions.colony_name AS phenotyping_colony_name,

              CASE WHEN top_production.mi_aborted_count IS NULL THEN 0 ELSE top_production.mi_aborted_count END AS mi_aborted_count,
              top_production.mi_aborted_max_date::date AS mi_aborted_max_date,
              CASE WHEN top_production.allele_mod_aborted_count IS NULL THEN 0 ELSE top_production.allele_mod_aborted_count END AS allele_mod_aborted_count,
              top_production.allele_mod_aborted_max_date::date AS allele_mod_aborted_max_date

          FROM mi_plans
          JOIN mi_plan_priorities ON mi_plan_priorities.id = mi_plans.priority_id
          JOIN mi_plan_sub_projects On mi_plan_sub_projects.id = mi_plans.sub_project_id
          JOIN genes ON genes.id = mi_plans.gene_id
          JOIN consortia ON consortia.id = mi_plans.consortium_id
          LEFT JOIN centres ON centres.id = mi_plans.production_centre_id
          #{if production_condition.blank?
              "LEFT JOIN top_production ON mi_plans.id = top_production.mi_plan_id"
            else
              "JOIN top_production ON mi_plans.id = top_production.mi_plan_id"
            end
          }
          LEFT JOIN (mouse_allele_mods JOIN colonies mi_attempt_colony ON mouse_allele_mods.parent_colony_id = mi_attempt_colony.id JOIN colonies mouse_allele_mod_colony ON mouse_allele_mod_colony.mouse_allele_mod_id = mouse_allele_mods.id) ON mouse_allele_mods.id = top_production.mouse_allele_mod_id
          LEFT JOIN mi_attempts ON mi_attempts.id = mi_attempt_colony.mi_attempt_id OR mi_attempts.id = top_production.mi_attempt_id
          LEFT JOIN (top_phenotyping_production JOIN phenotyping_productions ON phenotyping_productions.id = top_phenotyping_production.phenotyping_production_id
                    )ON top_phenotyping_production.mi_plan_id = top_production.mi_plan_id

          JOIN mi_plan_statuses ON mi_plan_statuses.id = mi_plans.status_id
          LEFT JOIN mi_plan_status_stamps AS assigned          ON assigned.mi_plan_id = mi_plans.id          AND assigned.status_id = 1
          LEFT JOIN mi_plan_status_stamps AS es_qc_in_progress ON es_qc_in_progress.mi_plan_id = mi_plans.id AND es_qc_in_progress.status_id = 8
          LEFT JOIN mi_plan_status_stamps AS es_qc_complete    ON es_qc_complete.mi_plan_id = mi_plans.id    AND es_qc_complete.status_id = 9
          LEFT JOIN mi_plan_status_stamps AS es_qc_fail        ON es_qc_fail.mi_plan_id = mi_plans.id        AND es_qc_fail.status_id = 10

          LEFT JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
          LEFT JOIN mi_attempt_status_stamps AS in_progress_stamps ON in_progress_stamps.mi_attempt_id = mi_attempts.id AND in_progress_stamps.status_id = 1
          LEFT JOIN mi_attempt_status_stamps AS gc_stamps          ON gc_stamps.mi_attempt_id = mi_attempts.id          AND gc_stamps.status_id = 2
          LEFT JOIN mi_attempt_status_stamps AS aborted_stamps     ON aborted_stamps.mi_attempt_id = mi_attempts.id     AND aborted_stamps.status_id = 3
          LEFT JOIN mi_attempt_status_stamps AS chimearic_stamps   ON chimearic_stamps.mi_attempt_id = mi_attempts.id   AND chimearic_stamps.status_id = 4

          LEFT JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
          LEFT JOIN mouse_allele_mod_status_stamps AS mam_aborted_statuses ON mam_aborted_statuses.mouse_allele_mod_id = mouse_allele_mods.id AND mam_aborted_statuses.status_id = 7
          LEFT JOIN mouse_allele_mod_status_stamps AS mam_registered_statuses ON mam_registered_statuses.mouse_allele_mod_id = mouse_allele_mods.id AND mam_registered_statuses.status_id = 1
          LEFT JOIN mouse_allele_mod_status_stamps AS mam_re_started_statuses ON mam_re_started_statuses.mouse_allele_mod_id = mouse_allele_mods.id AND mam_re_started_statuses.status_id = 3
          LEFT JOIN mouse_allele_mod_status_stamps AS mam_re_complete_statuses ON mam_re_complete_statuses.mouse_allele_mod_id = mouse_allele_mods.id AND mam_re_complete_statuses.status_id = 4
          LEFT JOIN mouse_allele_mod_status_stamps AS mam_cre_started_statuses ON mam_cre_started_statuses.mouse_allele_mod_id = mouse_allele_mods.id AND mam_cre_started_statuses.status_id = 5
          LEFT JOIN mouse_allele_mod_status_stamps AS mam_cre_complete_statuses ON mam_cre_complete_statuses.mouse_allele_mod_id = mouse_allele_mods.id AND mam_cre_complete_statuses.status_id = 6

          LEFT JOIN phenotyping_production_statuses ON phenotyping_production_statuses.id = phenotyping_productions.status_id
          LEFT JOIN phenotyping_production_status_stamps AS pp_aborted_statuses ON pp_aborted_statuses.phenotyping_production_id = phenotyping_productions.id AND pp_aborted_statuses.status_id = 5
          LEFT JOIN phenotyping_production_status_stamps AS pp_registered_statuses ON pp_registered_statuses.phenotyping_production_id = phenotyping_productions.id AND pp_registered_statuses.status_id = 1
          LEFT JOIN phenotyping_production_status_stamps AS pp_re_started_statuses ON pp_re_started_statuses.phenotyping_production_id = phenotyping_productions.id AND pp_re_started_statuses.status_id = 6
          LEFT JOIN phenotyping_production_status_stamps AS pp_re_complete_statuses ON pp_re_complete_statuses.phenotyping_production_id = phenotyping_productions.id AND pp_re_complete_statuses.status_id = 7
          LEFT JOIN phenotyping_production_status_stamps AS pp_started_statuses ON pp_started_statuses.phenotyping_production_id = phenotyping_productions.id AND pp_started_statuses.status_id = 3
          LEFT JOIN phenotyping_production_status_stamps AS pp_complete_statuses ON pp_complete_statuses.phenotyping_production_id = phenotyping_productions.id AND pp_complete_statuses.status_id = 4

          ORDER BY catagory, approach, allele_type, mi_plans.id

        EOF
      end

      def columns
        [ 'catagory',
          'approach',
          'allele_type',

          'mi_plan_id',                               # ids
          'mi_attempt_id',
          'modified_mouse_allele_mod_id',
          'mouse_allele_mod_id',
          'phenotyping_production_id',

          'consortium',                               # plan data
          'production_centre',
          'sub_project',
          'priority',

          'gene',
          'mgi_accession_id',

          'mi_attempt_external_ref',
          'mi_attempt_colony_name',                      # colony names
          'mouse_allele_mod_colony_name',
          'phenotyping_production_colony_name',

          'mi_plan_status',
          'assigned_date',                            # mi_plan statuses
          'assigned_es_cell_qc_in_progress_date',
          'assigned_es_cell_qc_complete_date',
          'aborted_es_cell_qc_failed_date',

          'mi_attempt_status',
          'micro_injection_aborted_date',             # mi_attempt_statuses
          'micro_injection_in_progress_date',
          'chimeras_obtained_date',
          'founder_obtained_date',
          'genotype_confirmed_date',

          'mouse_allele_mod_status',
          'mouse_allele_mod_registered_date',        # mouse_allele_mod_statuses
          'rederivation_started_date',
          'rederivation_complete_date',
          'cre_excision_started_date',
          'cre_excision_complete_date',

          'phenotyping_status',                      # phenotyping_statuses
          'phenotyping_registered_date',
          'phenotyping_rederivation_started_date',
          'phenotyping_rederivation_complete_date',
          'phenotyping_experiments_started_date',
          'phenotyping_started_date',
          'phenotyping_complete_date',
          'phenotype_attempt_aborted_date',

          'mi_aborted_count',
          'mi_aborted_max_date',
          'allele_mod_aborted_count',
          'allele_mod_aborted_max_date',

          'created_at'                                # created date
        ]
      end
    end
  end
end
