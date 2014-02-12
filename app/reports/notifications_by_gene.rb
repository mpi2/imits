class NotificationsByGene < PlannedMicroinjectionList

  def mi_plan_summary(production_centre = nil, consortium = nil)
    @mi_plan_summary = ActiveRecord::Base.connection.execute(self._mi_plan_summary(production_centre, consortium))
  end

  #def pretty_print_statuses
  #  hash = {}
  #  #marker_symbols = @mi_plan_summary.map {|item| item['marker_symbol'] }
  #  #Gene.where(:marker_symbol => marker_symbols).each do |gene|
  #  #  hash[gene.marker_symbol] = gene.relevant_status[:status]
  #  #end
  #  ##@mi_plan_summary.each do |row|
  #  ##  hash[row['marker_symbol']] = Gene.find_by_marker_symbol(row['marker_symbol']).relevant_status[:status]
  #  ##end
  #  hash
  #end

  def _mi_plan_summary(production_centre = nil, consortium = nil)
    where_clause = ''
    consortium_clause = "new_intermediate_report.consortium = '#{consortium}'" if consortium
    production_centre_clause = "new_intermediate_report.production_centre = '#{production_centre}'" if production_centre
    where_clause = "where #{consortium_clause}" if consortium
    where_clause = "where #{production_centre_clause}" if production_centre
    where_clause = "where #{consortium_clause} and #{production_centre_clause}" if consortium && production_centre

    <<-EOF
    with notification_details AS (
      SELECT genes.marker_symbol, genes.mgi_accession_id, count(*) as total
      FROM notifications
      JOIN contacts ON contacts.id = notifications.contact_id
      JOIN genes ON genes.id = notifications.gene_id
      WHERE contacts.report_to_public is true
      GROUP BY genes.marker_symbol, genes.mgi_accession_id
    )

    SELECT
      notification_details.marker_symbol as gene,
      notification_details.total as number_of_notifications,
      notification_details.marker_symbol as marker_symbol,
      notification_details.mgi_accession_id AS mgi_accession_id,
      --new_intermediate_report.overall_status AS status_name
      --,string_agg(distinct new_intermediate_report.mi_plan_status, ' | ') AS status_name
      string_agg(distinct new_intermediate_report.overall_status, ' | ') AS status_name
    FROM notification_details
      LEFT JOIN new_intermediate_report ON new_intermediate_report.gene = notification_details.marker_symbol

    #{where_clause}

    GROUP BY
      notification_details.marker_symbol,
      notification_details.total,
--      new_intermediate_report.mgi_accession_id,
      notification_details.mgi_accession_id
      --,new_intermediate_report.overall_status
      --,new_intermediate_report.mi_plan_status
    ORDER BY notification_details.total desc, notification_details.marker_symbol

    EOF

  end

end
