class ReadOnlyIndexReport

  ROW_LIMIT = 60

  def self.get_table_1
    title = "New IMPC Mouse Production Attempts"
    sql = %Q{
      select
      genes.marker_symbol,
      --'<strong>' || genes.marker_symbol || '</strong>' as marker_symbol,
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

    #  results.each do |res|
    #    res['marker_symbol_href'] = "<a href='/open/mi_plans/gene_selection?q[marker_symbol_or_mgi_accession_id_ci_in]=#{res['marker_symbol']}'>#{res['marker_symbol']}</a>"
    #  #  pp res
    #end

    results = results.to_a

    #http://localhost:3000/open/mi_plans/gene_selection?utf8=%E2%9C%93&q%5Bmarker_symbol_or_mgi_accession_id_ci_in%5D=cbx1
    #       &q%5Bmi_plans_consortium_id_in%5D%5B%5D=4
    #&q%5Bmi_plans_production_centre_id_in%5D%5B%5D=8
    #&q%5Bmi_plans_mi_attempts_id_not_null%5D=0
    #&q%5Bmi_plans_mi_attempts_status_stamps_status_id_in%5D=
    #&q%5Bmi_plans_phenotype_attempts_id_not_null%5D=0
    #&q%5Bmi_plans_phenotype_attempts_status_stamps_status_id_in%5D=

    #results.count.times do |i|
    #  results[i]['marker_symbol_href'] = "<a href='/open/mi_plans/gene_selection?q[marker_symbol_or_mgi_accession_id_ci_in]=#{results[i]['marker_symbol']}'>#{results[i]['marker_symbol']}</a>"
    #  results[i]['consortium_href'] = "<a href='/open/mi_plans/gene_selection?q[marker_symbol_or_mgi_accession_id_ci_in]=#{results[i]['marker_symbol']}&q%5Bmi_plans_consortium_id_in%5D%5B%5D=#{results[i]['consortium_id']}'>#{results[i]['consortium']}</a>"
    #  #results[i]['production_centre_href'] = "<a href='/open/mi_plans/gene_selection?q[marker_symbol_or_mgi_accession_id_ci_in]=#{results[i]['marker_symbol']}&q%5Bmi_plans_consortium_id_in%5D%5B%5D=#{results[i]['consortium_id']}&q%5Bmi_plans_production_centre_id_in%5D%5B%5D=#{results[i]['production_centre_id']}'>#{results[i]['production_centre']}</a>"
    #
    #  p = {
    #    'q[marker_symbol_or_mgi_accession_id_ci_in]' => results[i]['marker_symbol'],
    #    'q[mi_plans_consortium_id_in][]' => results[i]['consortium_id'],
    #    'q[mi_plans_production_centre_id_in][]' => results[i]['production_centre_id']
    #    }
    #
    #  results[i]['production_centre_href'] = "<a href='/open/mi_plans/gene_selection?#{p.to_query}'>#{results[i]['production_centre']}</a>"
    #end

    results.count.times do |i|
      p = { 'q[marker_symbol_or_mgi_accession_id_ci_in]' => results[i]['marker_symbol'] }
      results[i]['marker_symbol_href'] = "<a href='/open/mi_plans/gene_selection?#{p.to_query}'>#{results[i]['marker_symbol']}</a>"
      p.merge!({'q[mi_plans_consortium_id_in][]' => results[i]['consortium_id']})
      results[i]['consortium_href'] = "<a href='/open/mi_plans/gene_selection?#{p.to_query}'>#{results[i]['consortium']}</a>"
      p.merge!({'q[mi_plans_production_centre_id_in][]' => results[i]['production_centre_id']})
      results[i]['production_centre_href'] = "<a href='/open/mi_plans/gene_selection?#{p.to_query}'>#{results[i]['production_centre']}</a>"
    end

    #q[marker_symbol_or_mgi_accession_id_ci_in]=#{results[i]['marker_symbol']}&q%5Bmi_plans_consortium_id_in%5D%5B%5D=#{results[i]['consortium_id']}&q%5Bmi_plans_production_centre_id_in%5D%5B%5D=#{results[i]['production_centre_id']}


    #    pp results

    #my_hash.each { |k, v| my_hash[k] = v.upcase }

    #results.each { |k, v| results['marker_symbol_href'] = "<a href='/open/mi_plans/gene_selection?q[marker_symbol_or_mgi_accession_id_ci_in]=#{results['marker_symbol']}'>#{res['marker_symbol']}</a>" }

    #/open/mi_plans/gene_selection?utf8=✓&q[marker_symbol_or_mgi_accession_id_ci_in]=Cbx1

    results
  end

  def self.get_table_2
    title = "New IMPC Genotype Confirmed Mice"
    sql = %Q{
      select
      genes.marker_symbol as marker_symbol,
      --'<strong>' || genes.marker_symbol || '</strong>' as marker_symbol,
      consortia.name as consortium,
      consortia.id as consortium_id,
      centres.name as production_centre,
      centres.id as production_centre_id,
      --mi_date,
      mi_attempt_status_stamps.created_at as gc_date2,
      to_char(mi_date, 'DD Mon YYYY') as mi_date,
      to_char(mi_attempt_status_stamps.created_at, 'DD Mon YYYY') as gc_date,
      DATE_PART('day', current_date - mi_attempt_status_stamps.created_at) || ' days' as other_date
      from mi_attempts join mi_plans on mi_attempts.mi_plan_id = mi_plans.id
      join consortia on consortia.id = mi_plans.consortium_id
      join centres on centres.id = mi_plans.production_centre_id
      join genes on genes.id = mi_plans.gene_id
      join mi_attempt_status_stamps on mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id and mi_attempt_status_stamps.status_id = 2
      --where ((mi_attempt_status_stamps.created_at - current_date) >= -30)
      order by gc_date2 desc limit #{ROW_LIMIT}
    }

    results = ActiveRecord::Base.connection.execute(sql)

    results = results.to_a

    #results.count.times do |i|
    #  results[i]['marker_symbol_href'] = "<a href='/open/mi_plans/gene_selection?q[marker_symbol_or_mgi_accession_id_ci_in]=#{results[i]['marker_symbol']}'>#{results[i]['marker_symbol']}</a>"
    #  results[i]['consortium_href'] = "<a href='/open/mi_plans/gene_selection?q[marker_symbol_or_mgi_accession_id_ci_in]=#{results[i]['marker_symbol']}&q%5Bmi_plans_consortium_id_in%5D%5B%5D=#{results[i]['consortium_id']}'>#{results[i]['consortium']}</a>"
    #  results[i]['production_centre_href'] = "<a href='/open/mi_plans/gene_selection?q[marker_symbol_or_mgi_accession_id_ci_in]=#{results[i]['marker_symbol']}&q%5Bmi_plans_consortium_id_in%5D%5B%5D=#{results[i]['consortium_id']}&q%5Bmi_plans_production_centre_id_in%5D%5B%5D=#{results[i]['production_centre_id']}'>#{results[i]['production_centre']}</a>"
    #end

    results.count.times do |i|
      p = { 'q[marker_symbol_or_mgi_accession_id_ci_in]' => results[i]['marker_symbol'] }
      results[i]['marker_symbol_href'] = "<a href='/open/mi_plans/gene_selection?#{p.to_query}'>#{results[i]['marker_symbol']}</a>"
      p.merge!({'q[mi_plans_consortium_id_in][]' => results[i]['consortium_id']})
      results[i]['consortium_href'] = "<a href='/open/mi_plans/gene_selection?#{p.to_query}'>#{results[i]['consortium']}</a>"
      p.merge!({'q[mi_plans_production_centre_id_in][]' => results[i]['production_centre_id']})
      results[i]['production_centre_href'] = "<a href='/open/mi_plans/gene_selection?#{p.to_query}'>#{results[i]['production_centre']}</a>"
    end

    results
  end
end
