class PlannedMicroinjectionList #< Reports::Base

  attr_accessor :mi_plan_summary
  attr_accessor :pretty_print_non_assigned_mi_plans
  attr_accessor :pretty_print_assigned_mi_plans
  attr_accessor :pretty_print_aborted_mi_attempts
  attr_accessor :pretty_print_mi_attempts_in_progress
  attr_accessor :pretty_print_mi_attempts_genotype_confirmed
  attr_accessor :gene_pretty_prints

  def initialize(options = {})
    @crisprs = options[:crisprs] || false
    @show_eucommtoolscre_data = options.has_key?(:show_eucommtoolscre_data) ? options[:show_eucommtoolscre_data] : true

  end

  def mi_plan_summary(consortium = nil)
    @mi_plan_summary = ActiveRecord::Base.connection.execute(self.class.mi_plan_summary(consortium, @crisprs))
  end

  def pretty_print_non_assigned_mi_plans
    Gene.pretty_print_non_assigned_mi_plans_in_bulk({:result => gene_pretty_prints['non assigned plans'], :crispr => @crisprs, :show_eucommtoolscre_data => @show_eucommtoolscre_data})
  end

  def pretty_print_assigned_mi_plans
    Gene.pretty_print_assigned_mi_plans_in_bulk({:result => gene_pretty_prints['assigned plans'], :crispr => @crisprs, :show_eucommtoolscre_data => @show_eucommtoolscre_data})
  end

  def pretty_print_aborted_mi_attempts
    Gene.pretty_print_mi_attempts_in_bulk_helper({:result => gene_pretty_prints['aborted mi attempts'], :crispr => @crisprs, :show_eucommtoolscre_data => @show_eucommtoolscre_data})
  end

  def pretty_print_mi_attempts_in_progress
    Gene.pretty_print_mi_attempts_in_bulk_helper({:result => gene_pretty_prints['in progress mi attempts'], :crispr => @crisprs, :show_eucommtoolscre_data => @show_eucommtoolscre_data})
  end

  def pretty_print_mi_attempts_genotype_confirmed
    Gene.pretty_print_mi_attempts_in_bulk_helper({:result => gene_pretty_prints['genotype confirmed mi attempts'], :crispr => @crisprs, :show_eucommtoolscre_data => @show_eucommtoolscre_data})
  end

  def gene_pretty_prints
    @gene_pretty_prints ||= Gene.gene_production_summary({:crispr => @crisprs, :show_eucommtoolscre_data => @show_eucommtoolscre_data})
  end

## Class Methods
  def self.mi_plan_summary(consortium = nil, crisprs = false)

    sql = <<-EOF
    WITH plan_summary AS (
      SELECT summary.*
      FROM (#{ crisprs ? IntermediateReportSummaryByMiPlan.crispr_sql : IntermediateReportSummaryByMiPlan.es_cell_sql}) AS summary
      #{consortium.nil? ? "" : "WHERE summary.consortium IN ('#{consortium}')"}
    ),

    status_conflict_options AS (
    SELECT conflict_plans.plan_id AS plan_id, conflict_plans.gene AS marker_symbol, conflict_plans.consortium AS consortium_name,
           CASE
             WHEN conflict_plans.mi_attempt_status IN ('Genotype confirmed') THEN 'Inspect - GLT Mouse'
             WHEN conflict_plans.mi_attempt_status IN ('Micro-injection in progress', 'Chimeras obtained') THEN 'Inspect - MI Attempt'
             WHEN conflict_plans.plan_status IN ('#{MiPlan::Status.all_assigned.map{|status| status.name}.join("','")}') THEN 'Inspect - Conflict'
             WHEN conflict_plans.plan_status IN ('Conflict') THEN 'Conflict'
             ELSE NULL
           END AS possible_conflict
    FROM (#{IntermediateReportSummaryByMiPlan.es_cell_and_crsipr_sql}) AS conflict_plans
    )

    SELECT
      plan_summary.plan_id AS plan_id,
      plan_summary.gene AS marker_symbol,
      plan_summary.mgi_accession_id AS mgi_accession_id,
      plan_summary.consortium AS consortium_name,
      plan_summary.production_centre AS centre_name,
      plan_summary.sub_project AS sub_project_name,
      plan_summary.priority AS priority_name,
      plan_summary.plan_status AS status_name,
      to_char(plan_status_stamps.created_at, 'dd/mm/yyyy') AS status_date,
      to_char(plan_summary.assigned_date, 'dd/mm/yyyy') AS assign_date,
      plans.is_bespoke_allele AS bespoke,
      plans.mutagenesis_via_crispr_cas9 as mutagenesis_via_crispr_cas9,
      plans.is_conditional_allele AS conditional_allele,
      plans.conditional_tm1c AS conditional_tm1c,
      plans.is_deletion_allele AS deletion_allele,
      plans.is_cre_knock_in_allele AS cre_knock_in_allele,
      plans.is_cre_bac_allele AS cre_bac_allele,
      plans.point_mutation AS point_mutation,
      plans.conditional_point_mutation AS conditional_point_mutation,
      plans.allele_symbol_superscript AS allele_symbol_superscript,
      plans.completion_note AS completion_note,
      plans.phenotype_only AS phenotype_only,
      plans.ignore_available_mice AS ignore_available_mice,
      plans.recovery AS recovery,
      CASE
        WHEN plan_summary.plan_status = 'Inspect - GLT Mouse' THEN 'GLT mouse produced at: '
        WHEN plan_summary.plan_status = 'Inspect - MI Attempt' THEN 'MI already in progress at: '
        WHEN plan_summary.plan_status = 'Inspect - Conflict' THEN 'Other Assigned MI plans for: '
        WHEN plan_summary.plan_status = 'Conflict' THEN  'Other MI plans for: '
        ELSE ''
      END AS conflict_reason_text,
      string_agg(status_conflict_options.consortium_name, ' & ') AS conflict_reason,
      plan_summary.mi_aborted_count AS plan_aborted_count,
      to_char(plan_summary.mi_aborted_max_date, 'dd/mm/yyyy') AS plan_aborted_max_date

    FROM plan_summary
      JOIN plans ON plans.id = plan_summary.plan_id
      JOIN plan_status_stamps ON plan_status_stamps.plan_id = plan_summary.plan_id
        AND plan_status_stamps.status_id = plans.status_id
      LEFT JOIN status_conflict_options ON plan_summary.plan_id != status_conflict_options.plan_id
        AND plan_summary.plan_status = status_conflict_options.possible_conflict
        AND plan_summary.gene = status_conflict_options.marker_symbol

    GROUP BY
      plan_summary.plan_id,
      plan_summary.gene,
      plan_summary.mgi_accession_id,
      plan_summary.consortium,
      plan_summary.production_centre,
      plan_summary.sub_project,
      plan_summary.priority,
      plan_summary.plan_status,
      plan_status_stamps.created_at,
      plan_summary.assigned_date,
      plans.is_bespoke_allele,
      plans.mutagenesis_via_crispr_cas9,
      plans.is_conditional_allele,
      plans.conditional_tm1c,
      plans.is_deletion_allele,
      plans.is_cre_knock_in_allele,
      plans.is_cre_bac_allele,
      plans.point_mutation,
      plans.conditional_point_mutation,
      plans.allele_symbol_superscript,
      plans.completion_note,
      plans.phenotype_only,
      plans.ignore_available_mice,
      plans.recovery,
      plan_summary.mi_aborted_count,
      plan_summary.mi_aborted_max_date
    ORDER BY plan_summary.gene
      EOF

  end
end
