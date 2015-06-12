class NotificationsByGene < PlannedMicroinjectionList

  # dodgy use of temp tables
  # we're expecting to be run as a rake task to be cached

  def prepare_idg
    sql = 'SET client_min_messages=WARNING;drop table if exists tmp_idg_genes;'
    output = ActiveRecord::Base.connection.execute(sql)
    sql = 'SET client_min_messages=WARNING;drop table if exists tmp_idg_genes2;'
    output = ActiveRecord::Base.connection.execute(sql)

    sql = <<-EOF
    create temporary table tmp_idg_genes as
    select marker_symbol, id, mgi_accession_id from genes where lower(genes.marker_symbol) in
    EOF

    config = YAML.load_file("#{Rails.root}/config/idg_symbols.yml")
    config = config.sort.uniq
    idg_clause = config.map {|i| "'#{i}'"} * ', '
    sql += " (#{idg_clause.downcase})"

    output = ActiveRecord::Base.connection.execute(sql)

    sql = <<-EOF
    create temporary table tmp_idg_genes2 (marker_symbol text, id int, mgi_accession_id int)
    EOF

    output = ActiveRecord::Base.connection.execute(sql)

    sql = <<-EOF
    INSERT INTO tmp_idg_genes2 (marker_symbol, id, mgi_accession_id) values
    EOF

    sql_array = []

    config.each do |marker_symbol|
      sql_array.push "('#{marker_symbol}', -1, null)"
    end

    sql += sql_array.join ','

    output = ActiveRecord::Base.connection.execute(sql)

    sql = <<-EOF
    INSERT INTO tmp_idg_genes (marker_symbol, id, mgi_accession_id)
    select marker_symbol, id, mgi_accession_id from tmp_idg_genes2
    where lower(marker_symbol) not in (select lower(marker_symbol) from tmp_idg_genes)
    EOF

    output = ActiveRecord::Base.connection.execute(sql)

    s = 'select count(*) as count from tmp_idg_genes'
    r = ActiveRecord::Base.connection.execute(s)
  end

  def mi_plan_summary(production_centre = nil, consortium = nil, idg = false)
    if idg
      prepare_idg
      @mi_plan_summary = ActiveRecord::Base.connection.execute(self._mi_plan_summary_idg)
    else
      @mi_plan_summary = ActiveRecord::Base.connection.execute(self._mi_plan_summary(production_centre, consortium))
    end
  end

  def pretty_print_types_of_cells_available
    hash = {}
    @mi_plan_summary.each do |row|
      gene = Gene.find_by_marker_symbol(row['marker_symbol'])
      hash[row['marker_symbol']] = gene.pretty_print_types_of_cells_available if gene
    end
    hash
  end

#  def pretty_print_statuses
#    hash = {}
#    @mi_plan_summary.each do |row|
#      gene = Gene.find_by_marker_symbol(row['marker_symbol'])
#      hash[row['marker_symbol']] = gene.relevant_status[:status].to_s.humanize.titleize if gene
#    end
#    hash
#  end

  def _mi_plan_summary_idg()

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
    tmp_idg_genes.marker_symbol as gene,
    coalesce(notification_details.total, 0) as number_of_notifications,
    tmp_idg_genes.marker_symbol as marker_symbol,
    tmp_idg_genes.mgi_accession_id AS mgi_accession_id
    FROM tmp_idg_genes
    LEFT JOIN notification_details ON tmp_idg_genes.marker_symbol = notification_details.marker_symbol
    GROUP BY
    tmp_idg_genes.marker_symbol,
    notification_details.total,
    tmp_idg_genes.mgi_accession_id
    ORDER BY notification_details.total desc, tmp_idg_genes.marker_symbol
    EOF

    sql
  end

  def _mi_plan_summary(production_centre = nil, consortium = nil)
    where_clause = []
    all = consortium == '<all>' ? true : false
    none = consortium == '<none>' ? true : false
    consortium = nil if ['<all>'].include?(consortium)

    if !consortium.nil?
      if production_centre.nil?
        intermediate_table = IntermediateReportSummaryByConsortia
      else
        intermediate_table = IntermediateReportSummaryByCentreAndConsortia
        where_clause.push "intermediate_report.production_centre = '#{production_centre}'"
      end
    else
      if production_centre.nil?
        intermediate_table = IntermediateReportSummaryByGene
      else
        intermediate_table = IntermediateReportSummaryByCentre
        where_clause.push "intermediate_report.production_centre = '#{production_centre}'"
      end
    end

    if none
      where_clause.push "intermediate_report.consortium is null"
    elsif consortium.to_s.length > 0
      where_clause.push "intermediate_report.consortium = '#{consortium}'"
    end

    where_clause = 'where ' + where_clause.join(' and ') if where_clause.length > 0
    where_clause = '' if where_clause.length < 1

    sql = <<-EOF
      WITH intermediate_report AS #{intermediate_table}

      SELECT
        genes.marker_symbol as gene,
        count(*) as number_of_notifications,
        genes.marker_symbol as marker_symbol,
        genes.mgi_accession_id AS mgi_accession_id,
        intermediate_report.overall_status AS status
      FROM notifications
        JOIN contacts ON contacts.id = notifications.contact_id and contacts.report_to_public is true
        JOIN genes ON genes.id = notifications.gene_id
        LEFT JOIN intermediate_report ON intermediate_report.gene = genes.marker_symbol
        #{where_clause}
      GROUP BY genes.marker_symbol, genes.mgi_accession_id, intermediate_report.overall_status
      ORDER BY number_of_notifications desc, marker_symbol, intermediate_report.overall_status
    EOF

    sql
  end
end
