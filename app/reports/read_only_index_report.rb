class ReadOnlyIndexReport

  ROW_LIMIT = 10
  ROOT = '/open/mi_plans/gene_selection'

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
      where (mi_date - current_date >= -30)
      order by mi_date desc limit #{ROW_LIMIT}
    }

    results = ActiveRecord::Base.connection.execute(sql)

    add_links(results)
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
      order by gc_date2 desc limit #{ROW_LIMIT}
    }

    results = ActiveRecord::Base.connection.execute(sql)

    add_links(results)
  end

  def self.add_links(results)
    results = results.to_a

    results.count.times do |i|
      p = { 'q[marker_symbol_or_mgi_accession_id_ci_in]' => results[i]['marker_symbol'] }
      results[i]['marker_symbol_href'] = "<a href='#{ROOT}?#{p.to_query}'>#{results[i]['marker_symbol']}</a>"
      p.merge!({'q[mi_plans_consortium_id_in][]' => results[i]['consortium_id']})
      results[i]['consortium_href'] = "<a href='#{ROOT}?#{p.to_query}'>#{results[i]['consortium']}</a>"
      p.merge!({'q[mi_plans_production_centre_id_in][]' => results[i]['production_centre_id']})
      results[i]['production_centre_href'] = "<a href='#{ROOT}?#{p.to_query}'>#{results[i]['production_centre']}</a>"
    end

    results
  end

  private_class_method :add_links
end
