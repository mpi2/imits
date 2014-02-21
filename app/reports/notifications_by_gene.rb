class NotificationsByGene < PlannedMicroinjectionList

  def mi_plan_summary(production_centre = nil, consortium = nil)
    @mi_plan_summary = ActiveRecord::Base.connection.execute(self._mi_plan_summary(production_centre, consortium))
  end

  def _mi_plan_summary(production_centre = nil, consortium = nil)
    where_clause = ''
    consortium_clause = "new_intermediate_report.consortium = '#{consortium}'" if consortium
    production_centre_clause = "new_intermediate_report.production_centre = '#{production_centre}'" if production_centre
    where_clause = "where #{consortium_clause}" if consortium
    where_clause = "where #{production_centre_clause}" if production_centre
    where_clause = "where #{consortium_clause} and #{production_centre_clause}" if consortium && production_centre

    <<-EOF
    with notification_details AS (
      SELECT genes.marker_symbol, count(*) as total
      FROM notifications
      JOIN contacts ON contacts.id = notifications.contact_id
      JOIN genes ON genes.id = notifications.gene_id
      WHERE contacts.report_to_public is true
      GROUP BY genes.marker_symbol
    )

    SELECT
      notification_details.marker_symbol as gene,
      notification_details.total as number_of_notifications,
      notification_details.marker_symbol as marker_symbol,
      new_intermediate_report.mgi_accession_id AS mgi_accession_id
    FROM notification_details
      LEFT JOIN new_intermediate_report ON new_intermediate_report.gene = notification_details.marker_symbol

    #{where_clause}

    GROUP BY
      notification_details.marker_symbol,
      notification_details.total,
      new_intermediate_report.mgi_accession_id
    ORDER BY notification_details.total desc, notification_details.marker_symbol

    EOF

  end

end
