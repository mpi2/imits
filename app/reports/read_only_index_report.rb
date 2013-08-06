class ReadOnlyIndexReport

  ROW_LIMIT = 10

  def self.get_new_impc_mouse_prod_attempts_table
    sql = %Q{
      select
        genes.marker_symbol,
        consortia.name as consortium,
        consortia.id as consortium_id,
        centres.name as production_centre,
        centres.id as production_centre_id,
        to_char(mi_date, 'DD Mon YYYY') as mi_date
      from mi_attempts join mi_plans on mi_attempts.mi_plan_id = mi_plans.id
      join consortia on consortia.id = mi_plans.consortium_id
      join centres on centres.id = mi_plans.production_centre_id
      join genes on genes.id = mi_plans.gene_id
      where (mi_date - current_date >= -30) and mi_attempts.report_to_public = true and mi_plans.report_to_public = true
      order by mi_date desc limit #{ROW_LIMIT}
    }

    results = ActiveRecord::Base.connection.execute(sql)

  end

  def self.get_new_impc_gc_mice_table
    sql = %Q{
      select
        genes.marker_symbol as marker_symbol,
        consortia.name as consortium,
        consortia.id as consortium_id,
        centres.name as production_centre,
        centres.id as production_centre_id,
        mi_attempt_status_stamps.created_at as gc_date2,
        to_char(mi_date, 'DD Mon YYYY') as mi_date,
        to_char(mi_attempt_status_stamps.created_at, 'DD Mon YYYY') as gc_date,
        DATE_PART('day', current_date - mi_attempt_status_stamps.created_at) || ' days' as other_date
      from mi_attempts join mi_plans on mi_attempts.mi_plan_id = mi_plans.id
      join consortia on consortia.id = mi_plans.consortium_id
      join centres on centres.id = mi_plans.production_centre_id
      join genes on genes.id = mi_plans.gene_id
      join mi_attempt_status_stamps on mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id and mi_attempt_status_stamps.status_id = 2
      where mi_attempts.report_to_public = true and mi_plans.report_to_public = true
      order by gc_date2 desc limit #{ROW_LIMIT}
    }

    results = ActiveRecord::Base.connection.execute(sql)

  end

end
