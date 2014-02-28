class NotificationsByGene < PlannedMicroinjectionList

  def mi_plan_summary(production_centre = nil, consortium = nil, idg = false)
    @mi_plan_summary = ActiveRecord::Base.connection.execute(self._mi_plan_summary(production_centre, consortium, idg))
  end

  def pretty_print_types_of_cells_available
    hash = {}
    @mi_plan_summary.each do |row|
      hash[row['marker_symbol']] = Gene.find_by_marker_symbol(row['marker_symbol']).pretty_print_types_of_cells_available.gsub('<br/>',' ')
    end
    hash
  end

  def pretty_print_statuses
    hash = {}
    @mi_plan_summary.each do |row|
      #hash[row['marker_symbol']] = Gene.find_by_marker_symbol(row['marker_symbol']).relevant_status[:status]
      hash[row['marker_symbol']] = Gene.find_by_marker_symbol(row['marker_symbol']).relevant_status_new[:status]
    end
    hash
  end

  def _mi_plan_summary(production_centre = nil, consortium = nil, idg = false)
    where_clause = []

    where_clause.push "new_intermediate_report.consortium = '#{consortium}'" if consortium
    where_clause.push "new_intermediate_report.production_centre = '#{production_centre}'" if production_centre

    if idg
      config = YAML.load_file("#{Rails.root}/config/idg_symbols.yml")
      idg_clause = config.map {|i| "'#{i}'"} * ', '
      where_clause.push "lower(new_intermediate_report.gene) in (#{idg_clause.downcase})"
    end

    if where_clause.length > 0
      where_clause = ' where ' + where_clause.join(' and ')
    else
      where_clause = ''
    end

    #where_clause = "where #{consortium_clause}" if consortium
    #where_clause = "where #{production_centre_clause}" if production_centre
    #where_clause = "where #{idg_clause}" if idg
    #where_clause = "where #{consortium_clause} and #{production_centre_clause}" if consortium && production_centre

    sql = <<-EOF
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
      string_agg(distinct new_intermediate_report.overall_status, ' | ') AS status_name
    FROM notification_details
      LEFT JOIN new_intermediate_report ON new_intermediate_report.gene = notification_details.marker_symbol

    #{where_clause}

    GROUP BY
      notification_details.marker_symbol,
      notification_details.total,
      notification_details.mgi_accession_id
    ORDER BY notification_details.total desc, notification_details.marker_symbol

    EOF

    #if idg
    #  config = YAML.load_file("#{Rails.root}/config/idg_symbols.yml")
    #  in_clause = config.map {|i| "'#{i}'"} * ', '
    #  sql.gsub!(/IDG_SUBS/, "and notification_details.marker_symbol in (#{in_clause})")
    #else
    #  sql.gsub!(/IDG_SUBS/, '')
    #end

    puts "#### sql: #{sql}"

    sql
  end

end
