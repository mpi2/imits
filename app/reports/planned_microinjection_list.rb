class PlannedMicroinjectionList #< Reports::Base

  attr_accessor :mi_plan_summary
  attr_accessor :pretty_print_non_assigned_mi_plans
  attr_accessor :pretty_print_assigned_mi_plans
  attr_accessor :pretty_print_aborted_mi_attempts
  attr_accessor :pretty_print_mi_attempts_in_progress
  attr_accessor :pretty_print_mi_attempts_genotype_confirmed
  attr_accessor :gene_pretty_prints

  def mi_plan_summary(consortium = nil, crisprs = false)
    @crisprs = crisprs
    @mi_plan_summary = ActiveRecord::Base.connection.execute(self.class.mi_plan_summary(consortium, crisprs))
  end

  def pretty_print_non_assigned_mi_plans
    Gene.pretty_print_non_assigned_mi_plans_in_bulk(nil, gene_pretty_prints['non assigned plans'], @crisprs)
  end

  def pretty_print_assigned_mi_plans
    Gene.pretty_print_assigned_mi_plans_in_bulk(nil, gene_pretty_prints['assigned plans'], @crisprs)
  end

  def pretty_print_aborted_mi_attempts
    Gene.pretty_print_mi_attempts_in_bulk_helper(nil, nil, nil, gene_pretty_prints['aborted mi attempts'], @crisprs)
  end

  def pretty_print_mi_attempts_in_progress
    Gene.pretty_print_mi_attempts_in_bulk_helper(nil, nil, nil, gene_pretty_prints['in progress mi attempts'], @crisprs)
  end

  def pretty_print_mi_attempts_genotype_confirmed
    Gene.pretty_print_mi_attempts_in_bulk_helper(nil, nil, nil, gene_pretty_prints['genotype confirmed mi attempts'], @crisprs)
  end

  def gene_pretty_prints
    @gene_pretty_prints ||= Gene.gene_production_summary nil, nil, nil, @crisprs
  end

## Class Methods
  def self.mi_plan_summary(consortium = nil, crisprs = false)

    sql = <<-EOF
    WITH mi_attempt_counts AS (
      SELECT mi_plans.id AS plan_id, SUM(CASE WHEN mi_attempt_statuses.name = 'Micro-injection aborted' THEN 1 ELSE 0 END) AS plan_aborted_count,
             max(CASE WHEN mi_attempt_statuses.name = 'Micro-injection aborted' THEN mi_attempt_status_stamps.created_at ELSE NULL END ) AS plan_aborted_max_date --,
             --mi_plans.mutagenesis_via_crispr_cas9 as mutagenesis_via_crispr_cas9
        FROM mi_plans
        JOIN consortia ON consortia.id = mi_plans.consortium_id #{consortium.nil? ? "" : "AND consortia.name = '#{consortium}'"} #{crisprs ? 'and mi_plans.mutagenesis_via_crispr_cas9 is true' : ''}
        LEFT JOIN (mi_attempts JOIN mi_attempt_statuses ON mi_attempts.status_id = mi_attempt_statuses.id
                               JOIN mi_attempt_status_stamps ON mi_attempt_status_stamps.status_id = mi_attempt_statuses.id AND mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id
                  ) ON mi_attempts.mi_plan_id = mi_plans.id
      GROUP BY mi_plans.id
   ),

    status_conflict_options AS (
    SELECT new_intermediate_report.mi_plan_id AS mi_plan_id, new_intermediate_report.gene AS marker_symbol, new_intermediate_report.consortium AS consortium_name,
           CASE
             WHEN new_intermediate_report.mi_attempt_status IN ('Genotype confirmed') THEN 'Inspect - GLT Mouse'
             WHEN new_intermediate_report.mi_attempt_status IN ('Micro-injection in progress', 'Chimeras obtained') THEN 'Inspect - MI Attempt'
             WHEN new_intermediate_report.mi_plan_status IN ('#{MiPlan::Status.all_assigned.map{|status| status.name}.join("','")}') THEN 'Inspect - Conflict'
             WHEN new_intermediate_report.mi_plan_status IN ('Conflict') THEN 'Conflict'
             ELSE NULL
           END AS possible_conflict
    FROM new_intermediate_report
    )

    SELECT
      new_intermediate_report.mi_plan_id AS mi_plan_id,
      new_intermediate_report.gene AS marker_symbol,
      new_intermediate_report.mgi_accession_id AS mgi_accession_id,
      new_intermediate_report.consortium AS consortium_name,
      new_intermediate_report.production_centre AS centre_name,
      new_intermediate_report.sub_project AS sub_project_name,
      new_intermediate_report.priority AS priority_name,
      new_intermediate_report.mi_plan_status AS status_name,
      to_char(mi_plan_status_stamps.created_at, 'dd/mm/yyyy') AS status_date,
      to_char(new_intermediate_report.assigned_date, 'dd/mm/yyyy') AS assign_date,
      mi_plans.is_bespoke_allele AS bespoke,
      mi_plans.mutagenesis_via_crispr_cas9 as mutagenesis_via_crispr_cas9,
      mi_plans.is_conditional_allele AS conditional_allele,
      mi_plans.conditional_tm1c AS conditional_tm1c,
      mi_plans.is_deletion_allele AS deletion_allele,
      mi_plans.is_cre_knock_in_allele AS cre_knock_in_allele,
      mi_plans.is_cre_bac_allele AS cre_bac_allele,
      mi_plans.point_mutation AS point_mutation,
      mi_plans.conditional_point_mutation AS conditional_point_mutation,
      mi_plans.allele_symbol_superscript AS allele_symbol_superscript,
      mi_plans.completion_note AS completion_note,
      mi_plans.phenotype_only AS phenotype_only,
      mi_plans.ignore_available_mice AS ignore_available_mice,
      mi_plans.recovery AS recovery,
      CASE
        WHEN mi_plan_statuses.name = 'Inspect - GLT Mouse' THEN 'GLT mouse produced at: '
        WHEN mi_plan_statuses.name = 'Inspect - MI Attempt' THEN 'MI already in progress at: '
        WHEN mi_plan_statuses.name = 'Inspect - Conflict' THEN 'Other Assigned MI plans for: '
        WHEN mi_plan_statuses.name = 'Conflict' THEN  'Other MI plans for: '
        ELSE ''
      END AS conflict_reason_text,
      string_agg(status_conflict_options.consortium_name, ', ') AS conflict_reason,
      mi_attempt_counts.plan_aborted_count AS plan_aborted_count,
      to_char(mi_attempt_counts.plan_aborted_max_date, 'dd/mm/yyyy') AS plan_aborted_max_date

    FROM mi_attempt_counts
      JOIN mi_plans ON mi_plans.id = mi_attempt_counts.plan_id #{crisprs ? 'and mi_plans.mutagenesis_via_crispr_cas9 is true' : ''}
      JOIN new_intermediate_report ON new_intermediate_report.mi_plan_id = mi_attempt_counts.plan_id #{crisprs ? 'and new_intermediate_report.mutagenesis_via_crispr_cas9 is true' : ''}
      JOIN mi_plan_statuses ON mi_plan_statuses.name = new_intermediate_report.mi_plan_status
      JOIN mi_plan_status_stamps ON mi_plan_status_stamps.mi_plan_id = new_intermediate_report.mi_plan_id AND mi_plan_status_stamps.status_id = mi_plan_statuses.id
      LEFT JOIN status_conflict_options ON new_intermediate_report.mi_plan_id != status_conflict_options.mi_plan_id AND mi_plan_statuses.name = status_conflict_options.possible_conflict AND new_intermediate_report.gene = status_conflict_options.marker_symbol
    GROUP BY
      new_intermediate_report.mi_plan_id,
      new_intermediate_report.gene,
      new_intermediate_report.mgi_accession_id,
      new_intermediate_report.consortium,
      new_intermediate_report.production_centre,
      new_intermediate_report.sub_project,
      new_intermediate_report.priority,
      new_intermediate_report.mi_plan_status,
      mi_plan_status_stamps.created_at,
      new_intermediate_report.assigned_date,
      mi_plan_statuses.name,
      mi_plans.is_bespoke_allele,
      mi_plans.mutagenesis_via_crispr_cas9,
      mi_plans.is_conditional_allele,
      mi_plans.conditional_tm1c,
      mi_plans.is_deletion_allele,
      mi_plans.is_cre_knock_in_allele,
      mi_plans.is_cre_bac_allele,
      mi_plans.point_mutation,
      mi_plans.conditional_point_mutation,
      mi_plans.allele_symbol_superscript,
      mi_plans.completion_note,
      mi_plans.phenotype_only,
      mi_plans.ignore_available_mice,
      mi_plans.recovery,
      mi_attempt_counts.plan_aborted_count,
      mi_attempt_counts.plan_aborted_max_date
    ORDER BY new_intermediate_report.gene
      EOF

  end
end
