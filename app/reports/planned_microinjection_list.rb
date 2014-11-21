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
    WITH mi_plan_summary AS (
      SELECT summary.*
      FROM (#{ crisprs ? IntermediateReportSummaryByMiPlan.crispr_sql : IntermediateReportSummaryByMiPlan.es_cell_sql}) AS summary
      #{consortium.nil? ? "" : "WHERE summary.consortium IN ('#{consortium}')"}
    ),

    status_conflict_options AS (
    SELECT conflict_plans.mi_plan_id AS mi_plan_id, conflict_plans.gene AS marker_symbol, conflict_plans.consortium AS consortium_name,
           CASE
             WHEN conflict_plans.mi_attempt_status IN ('Genotype confirmed') THEN 'Inspect - GLT Mouse'
             WHEN conflict_plans.mi_attempt_status IN ('Micro-injection in progress', 'Chimeras obtained') THEN 'Inspect - MI Attempt'
             WHEN conflict_plans.mi_plan_status IN ('#{MiPlan::Status.all_assigned.map{|status| status.name}.join("','")}') THEN 'Inspect - Conflict'
             WHEN conflict_plans.mi_plan_status IN ('Conflict') THEN 'Conflict'
             ELSE NULL
           END AS possible_conflict
    FROM (#{IntermediateReportSummaryByMiPlan.es_cell_and_crsipr_sql}) AS conflict_plans
    )

    SELECT
      mi_plan_summary.mi_plan_id AS mi_plan_id,
      mi_plan_summary.gene AS marker_symbol,
      mi_plan_summary.mgi_accession_id AS mgi_accession_id,
      mi_plan_summary.consortium AS consortium_name,
      mi_plan_summary.production_centre AS centre_name,
      mi_plan_summary.sub_project AS sub_project_name,
      mi_plan_summary.priority AS priority_name,
      mi_plan_summary.mi_plan_status AS status_name,
      to_char(mi_plan_status_stamps.created_at, 'dd/mm/yyyy') AS status_date,
      to_char(mi_plan_summary.assigned_date, 'dd/mm/yyyy') AS assign_date,
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
        WHEN mi_plan_summary.mi_plan_status = 'Inspect - GLT Mouse' THEN 'GLT mouse produced at: '
        WHEN mi_plan_summary.mi_plan_status = 'Inspect - MI Attempt' THEN 'MI already in progress at: '
        WHEN mi_plan_summary.mi_plan_status = 'Inspect - Conflict' THEN 'Other Assigned MI plans for: '
        WHEN mi_plan_summary.mi_plan_status = 'Conflict' THEN  'Other MI plans for: '
        ELSE ''
      END AS conflict_reason_text,
      string_agg(status_conflict_options.consortium_name, ', ') AS conflict_reason,
      mi_plan_summary.mi_aborted_count AS plan_aborted_count,
      to_char(mi_plan_summary.mi_aborted_max_date, 'dd/mm/yyyy') AS plan_aborted_max_date

    FROM mi_plan_summary
      JOIN mi_plans ON mi_plans.id = mi_plan_summary.mi_plan_id
      JOIN mi_plan_status_stamps ON mi_plan_status_stamps.mi_plan_id = mi_plan_summary.mi_plan_id
        AND mi_plan_status_stamps.status_id = mi_plans.status_id
      LEFT JOIN status_conflict_options ON mi_plan_summary.mi_plan_id != status_conflict_options.mi_plan_id
        AND mi_plan_summary.mi_plan_status = status_conflict_options.possible_conflict
        AND mi_plan_summary.gene = status_conflict_options.marker_symbol
    GROUP BY
      mi_plan_summary.mi_plan_id,
      mi_plan_summary.gene,
      mi_plan_summary.mgi_accession_id,
      mi_plan_summary.consortium,
      mi_plan_summary.production_centre,
      mi_plan_summary.sub_project,
      mi_plan_summary.priority,
      mi_plan_summary.mi_plan_status,
      mi_plan_status_stamps.created_at,
      mi_plan_summary.assigned_date,
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
      mi_plan_summary.mi_aborted_count,
      mi_plan_summary.mi_aborted_max_date
    ORDER BY mi_plan_summary.gene
      EOF

  end
end
