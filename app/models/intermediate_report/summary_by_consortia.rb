module IntermediateReport::SummaryByConsortia
  class Generate < IntermediateReport::Base

     def to_s
       "#<IntermediateReportSummaryByConsortia::Generate size: #{size}>"
     end

    def self.table
      "intermediate_report_summary_by_consortia"
    end

    def self.report_sql

      mouse_pipelines = {'micro-injection' => 'false',
                         'mouse allele modification' => 'true',
                         'all' => ''}
      experiment_types = {'es cell' => 'false',
                         'crispr' => 'true',
                         'all' => ''}
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

     def self.experiment_report_logic(experiment_type, plan_condition)
         data = []
         data += ActiveRecord::Base.connection.execute(best_plans_report_sql(experiment_type, 'plan', plan_condition)).to_a
         return data
     end


     def self.filter_plans_sql(condition = nil)
       sql = <<-EOF
                  SELECT mi_plans.id, gene_id, consortium_id, status_id FROM mi_plans #{!condition.blank? ? "WHERE mi_plans.mutagenesis_via_crispr_cas9 = #{condition}" : ''}
              EOF
       return sql
     end

     def self.production_sql
       sql = <<-EOF
                  SELECT mi_attempts.id AS mi_attempt_id, NULL AS mouse_allele_mods_id, mi_attempts.mi_plan_id AS mi_plan_id,
                    mi_attempt_statuses.name AS production_status, mi_attempt_statuses.order_by AS production_status_order, mi_attempt_status_stamps.created_at AS production_status_order_status_stamp_created_at, false AS allele_modification
                  FROM mi_attempts
                    JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
                    JOIN mi_attempt_status_stamps ON mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id AND mi_attempt_status_stamps.status_id = mi_attempts.status_id
                  UNION

                  SELECT NULL AS mi_attempt_id, mouse_allele_mods.id AS mouse_allele_mods_id, mouse_allele_mods.mi_plan_id AS mi_plan_id,
                    mouse_allele_mod_statuses.name AS production_status, mouse_allele_mod_statuses.order_by AS production_status_order, mouse_allele_mod_status_stamps.created_at AS production_status_order_status_stamp_created_at, true AS allele_modification
                  FROM mouse_allele_mods
                    JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
                    JOIN mouse_allele_mod_status_stamps ON mouse_allele_mod_status_stamps.mouse_allele_mod_id = mouse_allele_mods.id AND mouse_allele_mod_status_stamps.status_id = mouse_allele_mods.status_id
                EOF
       return sql
     end

     def self.best_production_sql
       # Expected to be placed inside a WITH statement which already contains the temporary tables filtered_plans and filtered_production.
         sql = <<-EOF
            best_attempts_for_gene_consortia_and_status AS (
            SELECT
              filtered_plans.gene_id,
              filtered_plans.consortium_id,
              filtered_production.production_status_order AS order_by,
              filtered_production.production_status AS production_status,
              filtered_production.mi_attempt_id as mi_attempt_id,
              filtered_production.mouse_allele_mods_id as mouse_allele_mods_id
            FROM filtered_plans
              JOIN filtered_production ON filtered_plans.id = filtered_production.mi_plan_id
            ORDER BY
              filtered_plans.gene_id,
              filtered_plans.consortium_id,
              filtered_production.production_status_order DESC,
              filtered_production.production_status_order_status_stamp_created_at ASC
          ),

          att AS (
            SELECT
              best_attempts_for_gene_consortia_and_status.gene_id,
              best_attempts_for_gene_consortia_and_status.consortium_id,
              best_attempts_for_gene_consortia_and_status.order_by,
              first_value(best_attempts_for_gene_consortia_and_status.mi_attempt_id) OVER (PARTITION BY best_attempts_for_gene_consortia_and_status.gene_id, best_attempts_for_gene_consortia_and_status.consortium_id) AS mi_attempt_id,
              first_value(best_attempts_for_gene_consortia_and_status.mouse_allele_mods_id) OVER (PARTITION BY best_attempts_for_gene_consortia_and_status.gene_id, best_attempts_for_gene_consortia_and_status.consortium_id) AS mouse_allele_mod_id
            FROM best_attempts_for_gene_consortia_and_status
          ),

          top_production AS (
            SELECT DISTINCT att.gene_id, att.consortium_id, att.mi_attempt_id AS mi_attempt_id, att.mouse_allele_mod_id AS mouse_allele_mod_id
              FROM att
          )
        EOF
        return sql
     end

     def self.best_phenotyping_sql(crispr_condition = nil, excision__condition = nil)
       sql = <<-EOF
                  -- Statement description
                  -- 1. Select phenotyping either from crispr or es_cell experimental pipelines OR all phenotyping if condition is remove
                  -- 2. (IMPORTANT) Orders the phenotyping records based on the grouping fields and orders the statuses so the most advanced status is at the top of the group

                  phenotype_production_for_gene_consortia_and_status AS (
                    SELECT
                      mi_plans.gene_id,
                      mi_plans.consortium_id,
                      phenotyping_production_statuses.order_by,
                      phenotyping_productions.id as phenotype_productions_id
                    FROM phenotyping_productions
                      JOIN mi_plans ON mi_plans.id = phenotyping_productions.mi_plan_id
                      JOIN phenotyping_production_statuses ON phenotyping_production_statuses.id = phenotyping_productions.status_id
                      JOIN colonies ON colonies.id = phenotyping_productions.parent_colony_id #{!excision__condition.blank? ? (excision__condition ? "AND colonies.mouse_allele_mod_id IS NOT NULL" : "AND colonies.mouse_allele_mod_id IS NULL") : ''}
                      LEFT JOIN (mouse_allele_mods JOIN colonies mam_colonies ON mam_colonies.mouse_allele_mod_id = mouse_allele_mods.id) ON mam_colonies.id = phenotyping_productions.parent_colony_id
                      LEFT JOIN colonies mouse_allele_mod_colonies ON mouse_allele_mod_colonies.id = mouse_allele_mods.parent_colony_id
                      JOIN mi_attempts ON mi_attempts.id = mouse_allele_mod_colonies.mi_attempt_id OR colonies.mi_attempt_id = mi_attempts.id
                      JOIN mi_plans crispr_plan ON crispr_plan.id = mi_attempts.mi_plan_id #{!crispr_condition.blank? ? "AND mi_plans.mutagenesis_via_crispr_cas9 = #{crispr_condition}" : ''}
                    ORDER BY
                      mi_plans.gene_id,
                      mi_plans.consortium_id,
                      phenotyping_production_statuses.order_by DESC
                  ),

                  -- Statement description
                  -- We want to select a field that does not appear in the group. So we use a 'PARTITION' to group the data and put the id of the most advanced record in a field by selecting the top record in the group.

                  phenotyping_productions_grouped AS (
                    SELECT
                      phenotype_production_for_gene_consortia_and_status.gene_id,
                      phenotype_production_for_gene_consortia_and_status.consortium_id,
                      phenotype_production_for_gene_consortia_and_status.order_by,
                      first_value(phenotype_production_for_gene_consortia_and_status.phenotype_productions_id) OVER (PARTITION BY phenotype_production_for_gene_consortia_and_status.gene_id, phenotype_production_for_gene_consortia_and_status.consortium_id) AS phenotyping_production_id
                    FROM phenotype_production_for_gene_consortia_and_status
                  ),

                  -- Statement description
                  -- PARTITIONS do not collapse the data so we have many records in each group where the following fields are all identical. Therefore we select distinct records to remove duplicates.

                  top_phenotyping_production AS (
                    SELECT DISTINCT phenotyping_productions_grouped.gene_id, phenotyping_productions_grouped.consortium_id, phenotyping_productions_grouped.phenotyping_production_id
                    FROM phenotyping_productions_grouped
                  )

                EOF
       return sql
     end

      def self.best_plans_report_sql(experiment_type,approach, plan_condition = nil)
        <<-EOF
          WITH filtered_plans AS (#{filter_plans_sql(plan_condition)}),

          best_plans_for_gene_consortia_and_status AS (
            SELECT
              filtered_plans.gene_id,
              filtered_plans.consortium_id,
              (CASE
                WHEN mi_plan_statuses.name = 'Aborted - ES Cell QC Failed'       THEN 1
                WHEN mi_plan_statuses.name = 'Assigned'                          THEN 2
                WHEN mi_plan_statuses.name = 'Assigned - ES Cell QC In Progress' THEN 3
                WHEN mi_plan_statuses.name = 'Assigned - ES Cell QC Complete'    THEN 4
                ELSE 0
              END) As order_by,
              filtered_plans.id as mi_plan_id,
              mi_plan_status_stamps.created_at AS status_stamp_date
            FROM filtered_plans
              JOIN mi_plan_statuses ON mi_plan_statuses.id = filtered_plans.status_id AND mi_plan_statuses.name in ('Aborted - ES Cell QC Failed', 'Assigned', 'Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete')
              JOIN mi_plan_status_stamps ON mi_plan_status_stamps.mi_plan_id = filtered_plans.id AND mi_plan_status_stamps.status_id = mi_plan_statuses.id
            ORDER BY
              filtered_plans.gene_id,
              filtered_plans.consortium_id,
              mi_plan_statuses.order_by DESC,
              mi_plan_status_stamps.created_at ASC
          ),

          att AS (
            SELECT
              best_plans_for_gene_consortia_and_status.gene_id,
              best_plans_for_gene_consortia_and_status.consortium_id,
              best_plans_for_gene_consortia_and_status.order_by,
              first_value(best_plans_for_gene_consortia_and_status.mi_plan_id) OVER (PARTITION BY best_plans_for_gene_consortia_and_status.gene_id, best_plans_for_gene_consortia_and_status.consortium_id) AS mi_plan_id,
              min(best_plans_for_gene_consortia_and_status.status_stamp_date) OVER (PARTITION BY best_plans_for_gene_consortia_and_status.gene_id, best_plans_for_gene_consortia_and_status.consortium_id) AS commence_date
            FROM best_plans_for_gene_consortia_and_status
          ),

          top_mi_plans AS (
            SELECT DISTINCT filtered_plans.*, att.commence_date
              FROM filtered_plans
                JOIN att ON filtered_plans.id = att.mi_plan_id
          )

          SELECT
            '#{experiment_type}' AS catagory,
            '#{approach}' AS approach,
            'all' AS allele_type,
            genes.marker_symbol AS gene,
            genes.mgi_accession_id AS mgi_accession_id,
            consortia.name AS consortium,
            top_mi_plans.id AS mi_plan_id,
            NULL AS mi_attempt_id,
            NULL AS mouse_allele_mod_id,
            NULL AS phenotyping_production_id,

            top_mi_plans.commence_date AS gene_interest_date,

            mi_plan_statuses.name AS mi_plan_status,
            NULL AS mi_attempt_status,
            NULL AS mouse_allele_status,
            NULL AS phenotyping_status,

            assigned.created_at::date          AS assigned_date,
            es_qc_in_progress.created_at::date AS assigned_es_cell_qc_in_progress_date,
            es_qc_complete.created_at::date    AS assigned_es_cell_qc_complete_date,
            es_qc_fail.created_at::date        AS aborted_es_cell_qc_failed_date,

            NULL AS micro_injection_in_progress_date,
            NULL AS chimeras_obtained_date,
            NULL AS genotype_confirmed_date,
            NULL AS micro_injection_aborted_date,
            NULL AS phenotype_attempt_registered_date,
            NULL AS rederivation_started_date,
            NULL AS rederivation_complete_date,
            NULL AS cre_excision_started_date,
            NULL AS cre_excision_complete_date,
            NULL AS phenotype_attempt_aborted_date,
            NULL AS mi_attempt_colony_name,
            NULL AS mouse_allele_mod_colony_name,
            NULL AS phenotyping_production_colony_name
          FROM top_mi_plans
            JOIN genes ON genes.id = top_mi_plans.gene_id
            JOIN consortia ON consortia.id = top_mi_plans.consortium_id
            JOIN mi_plan_statuses ON mi_plan_statuses.id = top_mi_plans.status_id
            LEFT JOIN mi_plan_status_stamps AS assigned          ON assigned.mi_plan_id = top_mi_plans.id          AND assigned.status_id = 1
            LEFT JOIN mi_plan_status_stamps AS es_qc_in_progress ON es_qc_in_progress.mi_plan_id = top_mi_plans.id AND es_qc_in_progress.status_id = 8
            LEFT JOIN mi_plan_status_stamps AS es_qc_complete    ON es_qc_complete.mi_plan_id = top_mi_plans.id    AND es_qc_complete.status_id = 9
            LEFT JOIN mi_plan_status_stamps AS es_qc_fail        ON es_qc_fail.mi_plan_id = top_mi_plans.id        AND es_qc_fail.status_id = 10
          ORDER BY catagory, approach, allele_type, gene_id, consortium_id
        EOF
      end

      def self.best_production_report_sql(experiment_type, approach, plan_condition = nil , production_condition = nil)
        <<-EOF
          --
          WITH filtered_plans AS (#{filter_plans_sql(plan_condition)}), filtered_production AS (SELECT * FROM (#{production_sql}) AS production #{!production_condition.blank? ? "WHERE production.allele_modification = #{production_condition}" : ""} ), #{best_production_sql}, #{best_phenotyping_sql(plan_condition, production_condition)}

          SELECT
              '#{experiment_type}' AS catagory,
              '#{approach}' AS approach,
              'all' AS allele_type,

              genes.marker_symbol AS gene,
              genes.mgi_accession_id AS mgi_accession_id,
              consortia.name AS consortium,

              NULL AS mi_plan_id,
              mi_attempts.id AS mi_attempt_id,
              mouse_allele_mods.id AS mouse_allele_mod_id,
              NULL AS phenotyping_production_id,

              NULL AS mi_plan_status,
              mi_attempt_statuses.name AS mi_attempt_status,
              mouse_allele_mod_statuses.name AS mouse_allele_status,
              phenotyping_production_statuses.name AS phenotyping_status,

              NULL AS gene_interest_date,
              NULL AS assigned_date,
              NULL AS assigned_es_cell_qc_in_progress_date,
              NULL AS assigned_es_cell_qc_complete_date,
              NULL AS aborted_es_cell_qc_failed_date,

              in_progress_stamps.created_at::date AS micro_injection_in_progress_date,
              chimearic_stamps.created_at::date AS chimeras_obtained_date,
              gc_stamps.created_at::date AS genotype_confirmed_date,
              aborted_stamps.created_at::date AS micro_injection_aborted_date,

              mam_registered_statuses.created_at::date AS mouse_allele_mod_registered_date,
              mam_re_started_statuses.created_at::date AS rederivation_started_date,
              mam_re_complete_statuses.created_at::date AS rederivation_complete_date,
              mam_cre_started_statuses.created_at::date AS cre_excision_started_date,
              mam_cre_complete_statuses.created_at::date AS cre_excision_complete_date,
              mam_aborted_statuses.created_at::date as phenotype_attempt_aborted_date,

              pp_registered_statuses.created_at::date AS phenotyping_registered_date,
              pp_re_started_statuses.created_at::date AS phenotyping_rederivation_started_date,
              pp_re_complete_statuses.created_at::date AS phenotyping_rederivation_complete_date,
              pp_started_statuses.created_at::date as phenotyping_started_date,
              phenotyping_productions.phenotyping_experiments_started::date as phenotyping_experiments_started_date,
              pp_complete_statuses.created_at::date as phenotyping_complete_date,
              pp_aborted_statuses.created_at::date as phenotype_attempt_aborted_date,

              NULL AS mi_attempt_colony_name,
              NULL AS mouse_allele_mod_colony_name,
              NULL AS phenotyping_production_colony_name

          FROM top_production
          JOIN genes ON genes.id = top_production.gene_id
          JOIN consortia ON consortia.id = top_production.consortium_id
          LEFT JOIN (mouse_allele_mods JOIN colonies mi_attempt_colonies ON mi_attempt_colonies.id = mouse_allele_mods.parent_colony_id) ON mouse_allele_mods.id = top_production.mouse_allele_mod_id
          JOIN mi_attempts ON mi_attempts.id = mi_attempt_colonies.mi_attempt_id OR mi_attempts.id = top_production.mi_attempt_id
          LEFT JOIN (top_phenotyping_production JOIN phenotyping_productions ON phenotyping_productions.id = top_phenotyping_production.phenotyping_production_id
                    )ON top_phenotyping_production.gene_id = top_production.gene_id  AND top_phenotyping_production.consortium_id = top_production.consortium_id

          LEFT JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.id
          LEFT JOIN mi_attempt_status_stamps AS in_progress_stamps ON in_progress_stamps.mi_attempt_id = mi_attempts.id AND in_progress_stamps.status_id = 1
          LEFT JOIN mi_attempt_status_stamps AS gc_stamps          ON gc_stamps.mi_attempt_id = mi_attempts.id          AND gc_stamps.status_id = 2
          LEFT JOIN mi_attempt_status_stamps AS aborted_stamps     ON aborted_stamps.mi_attempt_id = mi_attempts.id     AND aborted_stamps.status_id = 3
          LEFT JOIN mi_attempt_status_stamps AS chimearic_stamps   ON chimearic_stamps.mi_attempt_id = mi_attempts.id   AND chimearic_stamps.status_id = 4

          LEFT JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.id
          LEFT JOIN mouse_allele_mod_status_stamps AS mam_aborted_statuses ON mam_aborted_statuses.mouse_allele_mod_id = mouse_allele_mods.id AND mam_aborted_statuses.status_id = 7
          LEFT JOIN mouse_allele_mod_status_stamps AS mam_registered_statuses ON mam_registered_statuses.mouse_allele_mod_id = mouse_allele_mods.id AND mam_registered_statuses.status_id = 1
          LEFT JOIN mouse_allele_mod_status_stamps AS mam_re_started_statuses ON mam_re_started_statuses.mouse_allele_mod_id = mouse_allele_mods.id AND mam_re_started_statuses.status_id = 3
          LEFT JOIN mouse_allele_mod_status_stamps AS mam_re_complete_statuses ON mam_re_complete_statuses.mouse_allele_mod_id = mouse_allele_mods.id AND mam_re_complete_statuses.status_id = 4
          LEFT JOIN mouse_allele_mod_status_stamps AS mam_cre_started_statuses ON mam_cre_started_statuses.mouse_allele_mod_id = mouse_allele_mods.id AND mam_cre_started_statuses.status_id = 5
          LEFT JOIN mouse_allele_mod_status_stamps AS mam_cre_complete_statuses ON mam_cre_complete_statuses.mouse_allele_mod_id = mouse_allele_mods.id AND mam_cre_complete_statuses.status_id = 6

          LEFT JOIN phenotyping_production_statuses ON phenotyping_production_statuses.id = phenotyping_productions.id
          LEFT JOIN phenotyping_production_status_stamps AS pp_aborted_statuses ON pp_aborted_statuses.phenotyping_production_id = phenotyping_productions.id AND pp_aborted_statuses.status_id = 5
          LEFT JOIN phenotyping_production_status_stamps AS pp_registered_statuses ON pp_registered_statuses.phenotyping_production_id = phenotyping_productions.id AND pp_registered_statuses.status_id = 1
          LEFT JOIN phenotyping_production_status_stamps AS pp_re_started_statuses ON pp_re_started_statuses.phenotyping_production_id = phenotyping_productions.id AND pp_re_started_statuses.status_id = 6
          LEFT JOIN phenotyping_production_status_stamps AS pp_re_complete_statuses ON pp_re_complete_statuses.phenotyping_production_id = phenotyping_productions.id AND pp_re_complete_statuses.status_id = 7
          LEFT JOIN phenotyping_production_status_stamps AS pp_started_statuses ON pp_started_statuses.phenotyping_production_id = phenotyping_productions.id AND pp_started_statuses.status_id = 3
          LEFT JOIN phenotyping_production_status_stamps AS pp_complete_statuses ON pp_complete_statuses.phenotyping_production_id = phenotyping_productions.id AND pp_complete_statuses.status_id = 4

          ORDER BY catagory, approach, allele_type, genes.id, consortia.id

        EOF
      end


      def self.columns
        [
          'catagory',
          'approach',
          'allele_type',

          'gene',
          'mgi_accession_id',
          'consortium',                                  # plan data

          'mi_plan_id',                                  # ids
          'mi_attempt_id',
          'mouse_allele_mod_id',
          'phenotyping_production_id',

          'mi_attempt_external_ref',
          'mi_attempt_colony_name',                      # colony names
          'mouse_allele_mod_colony_name',
          'phenotyping_production_colony_name',

          'mi_plan_status',
          'gene_interest_date',
          'assigned_date',                               # plan statuses
          'assigned_es_cell_qc_in_progress_date',
          'assigned_es_cell_qc_complete_date',
          'aborted_es_cell_qc_failed_date',

          'mi_attempt_status',
          'micro_injection_in_progress_date',            # mi_attempt statuses
          'chimeras_obtained_date',
          'founder_obtained_date',
          'genotype_confirmed_date',
          'micro_injection_aborted_date',

          'mouse_allele_mod_status',
          'mouse_allele_mod_registered_date',           # mouse_allele_mod_statuses
          'rederivation_started_date',
          'rederivation_complete_date',
          'cre_excision_started_date',
          'cre_excision_complete_date',

          'phenotyping_status',                         # phenotyping statuses
          'phenotyping_registered_date',
          'phenotyping_rederivation_started_date',
          'phenotyping_rederivation_complete_date',
          'phenotyping_started_date',
          'phenotyping_experiments_started_date',
          'phenotyping_complete_date',
          'phenotype_attempt_aborted_date',

          'created_at'                                   # created date
        ]

      end
  end
end
