class MicroInjectionSummaryAndConflictsPresenter

  attr_accessor :consortia_by_priority,
    :consortia_by_status,
    :consortia_totals,
    :priority_totals,
    :status_totals,
    :consortia,
    :conflict_hash,
    :report_rows

  def initialize(options = {})
    @consortia_by_priority = {}
    @consortia_by_status = {}
    @consortia_totals = {}
    @priority_totals = {}
    @status_totals = {}
    @consortia = []

    self.generate_report
  end

  def execute_conflict_report
    @conflict_report ||= ActiveRecord::Base.connection.execute(self.class.conflict_report_sql).to_a
  end

  def execute_inspect_con_report
    @inspect_con_report ||= ActiveRecord::Base.connection.execute(self.class.inspect_con_report_sql).to_a
  end

  def execute_inspect_mis_report
    @inspect_mis_report ||= ActiveRecord::Base.connection.execute(self.class.inspect_mis_report_sql).to_a
  end

  def execute_inspect_gtc_report
    @inspect_gtc_report ||= ActiveRecord::Base.connection.execute(self.class.inspect_gtc_report_sql).to_a
  end

  def gene_count
    @gene_count ||= MiPlan.select('count(distinct(gene_id))')
                    .joins(:consortium)
                    .where(:consortium_id => self.class.impc_consortia_ids).first.attributes['count']
  end

  def generate_report
    self.class.mi_plans.each do |mi|
      consortium = mi.attributes.to_options[:consortium_name]
      priority     = mi.attributes.to_options[:priority_name]
      status     = mi.attributes.to_options[:status_name]
      count      = mi.attributes.to_options[:count]

      @consortia << consortium

      if @consortia_totals[consortium]
        @consortia_totals[consortium] += count.to_i
      else
        @consortia_totals[consortium] = count.to_i
      end

      if @priority_totals[priority]
        @priority_totals[priority] += count.to_i
      else
        @priority_totals[priority] = count.to_i
      end

      if @status_totals[status]
        @status_totals[status] += count.to_i
      else
        @status_totals[status] = count.to_i
      end

      if @consortia_by_priority["#{consortium} - #{priority}"]
        @consortia_by_priority["#{consortium} - #{priority}"] += count.to_i
      else
        @consortia_by_priority["#{consortium} - #{priority}"] = count.to_i
      end

      if @consortia_by_status["#{consortium} - #{status}"]
        @consortia_by_status["#{consortium} - #{status}"] += count.to_i
      else
        @consortia_by_status["#{consortium} - #{status}"] = count.to_i
      end

      if @consortia_by_priority["#{consortium} - #{priority} - #{status}"]
        @consortia_by_priority["#{consortium} - #{priority} - #{status}"] += count.to_i
      else
        @consortia_by_priority["#{consortium} - #{priority} - #{status}"] = count.to_i
      end
    end

    @consortia.uniq!

    @conflicting_mi_plans = MiPlan
      .joins(:consortium, :priority, :status)
      .includes(:production_centre, :sub_project)
      .where(:mi_plan_statuses => {:name => 'Conflict'})
      .order('consortia.name asc')
  end

  class << self

    def impc_consortia_ids
      @impc_consortia_ids ||= Consortium.where('name not in (?)', ['EUCOMM-EUMODIC','MGP-KOMP','UCD-KOMP']).map(&:id)
    end

    def priorities
      @priorities ||= MiPlan::Priority.all
    end

    def statuses
      @statuses ||= MiPlan::Status.order('order_by asc')
    end

    def mi_plans
      @mi_plans ||= MiPlan.select('consortia.name as consortium_name, mi_plan_priorities.name as priority_name, mi_plan_statuses.name as status_name, count(distinct(gene_id))')
                  .joins(:status, :priority, :consortium)
                  .where(:consortium_id => impc_consortia_ids, :is_bespoke_allele => false)
                  .order('consortia.name asc')
                  .group('consortium_name, priority_name, status_name')
    end

    def conflict_report_sql
      <<-EOF
        SELECT
          consortia.name AS consortium,
          mi_plan_sub_projects.name AS sub_project,
          mi_plans.is_bespoke_allele,
          centres.name AS production_centre,
          genes.marker_symbol AS marker_symbol,
          genes.mgi_accession_id AS mgi_accession_id,
          mi_plan_priorities.name AS priority,
          ARRAY(
            SELECT regexp_replace(conflicting_consortia.name, ' ', '_')
            FROM mi_plans AS conflicting_mi_plans
            JOIN consortia AS conflicting_consortia ON conflicting_consortia.id = conflicting_mi_plans.consortium_id

            WHERE
              conflicting_mi_plans.id != mi_plans.id
              AND
              genes.id = conflicting_mi_plans.gene_id 
              AND
              conflicting_mi_plans.id not in (SELECT distinct(mi_plan_id) FROM mi_attempts WHERE mi_attempts.is_active = true)
            
          ) AS reason_for_conflict
          

        FROM mi_plans

        JOIN consortia ON consortia.id = mi_plans.consortium_id
        LEFT JOIN mi_plan_sub_projects ON mi_plan_sub_projects.id = mi_plans.sub_project_id
        LEFT JOIN centres ON centres.id = mi_plans.production_centre_id
        JOIN genes ON genes.id = mi_plans.gene_id
        JOIN mi_plan_priorities ON mi_plan_priorities.id = mi_plans.priority_id
        JOIN mi_plan_statuses ON mi_plan_statuses.id = mi_plans.status_id

        WHERE mi_plan_statuses.code = 'con'

        ORDER BY consortia.name
      EOF
    end

    def inspect_con_report_sql
      <<-EOF
        SELECT
          consortia.name AS consortium,
          mi_plan_sub_projects.name AS sub_project,
          mi_plans.is_bespoke_allele,
          centres.name AS production_centre,
          genes.marker_symbol AS marker_symbol,
          genes.mgi_accession_id AS mgi_accession_id,
          mi_plan_priorities.name AS priority,
          ARRAY(
            SELECT regexp_replace(conflicting_consortia.name, ' ', '_')
            FROM mi_plans AS conflicting_mi_plans
            JOIN consortia AS conflicting_consortia ON conflicting_consortia.id = conflicting_mi_plans.consortium_id

            WHERE
        conflicting_mi_plans.id != mi_plans.id
      AND
        genes.id = conflicting_mi_plans.gene_id 
      AND
        conflicting_mi_plans.id not in (SELECT distinct(mi_plan_id) FROM mi_attempts WHERE mi_attempts.is_active = true)
      AND
        conflicting_mi_plans.status_id in (1, 8, 9)
            
          ) AS reason_for_conflict
          

        FROM mi_plans

        JOIN consortia ON consortia.id = mi_plans.consortium_id
        LEFT JOIN mi_plan_sub_projects ON mi_plan_sub_projects.id = mi_plans.sub_project_id
        LEFT JOIN centres ON centres.id = mi_plans.production_centre_id
        JOIN genes ON genes.id = mi_plans.gene_id
        JOIN mi_plan_priorities ON mi_plan_priorities.id = mi_plans.priority_id
        JOIN mi_plan_statuses ON mi_plan_statuses.id = mi_plans.status_id

        WHERE mi_plan_statuses.code = 'ins-con'

        ORDER BY consortia.name
      EOF
    end

    def inspect_mis_report_sql
      <<-EOF
        SELECT
          consortia.name AS consortium,
          mi_plan_sub_projects.name AS sub_project,
          mi_plans.is_bespoke_allele,
          centres.name AS production_centre,
          genes.marker_symbol AS marker_symbol,
          genes.mgi_accession_id AS mgi_accession_id,
          mi_plan_priorities.name AS priority,
          ARRAY(
            SELECT
              regexp_replace(conflicting_centre.name, ' ', '_') || '_(' || regexp_replace(conflicting_consortia.name, ' ', '_') || ')'
            FROM mi_plans AS conflicting_mi_plans
            JOIN consortia AS conflicting_consortia ON conflicting_consortia.id = conflicting_mi_plans.consortium_id
            JOIN centres AS conflicting_centre ON conflicting_centre.id = conflicting_mi_plans.production_centre_id

            WHERE
              conflicting_mi_plans.id != mi_plans.id
              AND
              genes.id = conflicting_mi_plans.gene_id 
              AND
              conflicting_mi_plans.id in (SELECT distinct(mi_plan_id) FROM mi_attempts)
            
          ) AS reason_for_conflict
          

        FROM mi_plans

        JOIN consortia ON consortia.id = mi_plans.consortium_id
        LEFT JOIN mi_plan_sub_projects ON mi_plan_sub_projects.id = mi_plans.sub_project_id
        LEFT JOIN centres ON centres.id = mi_plans.production_centre_id
        JOIN genes ON genes.id = mi_plans.gene_id
        JOIN mi_plan_priorities ON mi_plan_priorities.id = mi_plans.priority_id
        JOIN mi_plan_statuses ON mi_plan_statuses.id = mi_plans.status_id

        WHERE mi_plan_statuses.code = 'ins-mip'

        ORDER BY consortia.name
      EOF
    end

    def inspect_gtc_report_sql
      <<-EOF
        SELECT
          consortia.name AS consortium,
          mi_plan_sub_projects.name AS sub_project,
          mi_plans.is_bespoke_allele,
          centres.name AS production_centre,
          genes.marker_symbol AS marker_symbol,
          genes.mgi_accession_id AS mgi_accession_id,
          mi_plan_priorities.name AS priority,
          ARRAY(
            SELECT
              regexp_replace(conflicting_centre.name, ' ', '_') || '_(' || regexp_replace(conflicting_consortia.name, ' ', '_') || ')'
            FROM mi_plans AS conflicting_mi_plans
            JOIN consortia AS conflicting_consortia ON conflicting_consortia.id = conflicting_mi_plans.consortium_id
            JOIN centres AS conflicting_centre ON conflicting_centre.id = conflicting_mi_plans.production_centre_id

            WHERE
              conflicting_mi_plans.id != mi_plans.id
              AND
              genes.id = conflicting_mi_plans.gene_id 
              AND
              conflicting_mi_plans.id in (SELECT distinct(mi_plan_id) FROM mi_attempts WHERE mi_attempts.status_id = 2)
            
          ) AS reason_for_conflict
          

        FROM mi_plans

        JOIN consortia ON consortia.id = mi_plans.consortium_id
        LEFT JOIN mi_plan_sub_projects ON mi_plan_sub_projects.id = mi_plans.sub_project_id
        LEFT JOIN centres ON centres.id = mi_plans.production_centre_id
        JOIN genes ON genes.id = mi_plans.gene_id
        JOIN mi_plan_priorities ON mi_plan_priorities.id = mi_plans.priority_id
        JOIN mi_plan_statuses ON mi_plan_statuses.id = mi_plans.status_id

        WHERE mi_plan_statuses.code = 'ins-gtc'

        ORDER BY consortia.name      
      EOF
    end

  end

end