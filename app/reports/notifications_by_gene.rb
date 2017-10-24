class NotificationsByGene < PlannedMicroinjectionList

  # dodgy use of temp tables
  # we're expecting to be run as a rake task to be cached

  def mi_plan_summary(production_centre = nil, consortium = nil, nominated_type = false)
    if nominated_type == 'idg'
      @mi_plan_summary = ActiveRecord::Base.connection.execute(self._mi_plan_summary_idg)
    elsif nominated_type == 'cmg'
      @mi_plan_summary = ActiveRecord::Base.connection.execute(self._mi_plan_summary_cmg)
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
    WITH intermediate_report AS (#{IntermediateReportSummaryByGene.select_sql(category = 'all', approach = 'all')})

    SELECT genes.marker_symbol, 
           genes.mgi_accession_id, 
           count(*) as number_of_notifications, 
           gpa.idg, 
           gpa.cmg_tier1, 
           gpa.cmg_tier2,
           intermediate_report.overall_status AS status
    FROM genes
      JOIN gene_private_annotations gpa ON gpa.gene_id = genes.id AND gpa.idg = true
      LEFT JOIN (notifications JOIN contacts ON contacts.id = notifications.contact_id AND contacts.report_to_public is true) ON genes.id = notifications.gene_id
      LEFT JOIN intermediate_report ON intermediate_report.gene = genes.marker_symbol
    GROUP BY genes.marker_symbol, genes.mgi_accession_id, gpa.idg, gpa.cmg_tier1, gpa.cmg_tier2, intermediate_report.overall_status
    ORDER BY genes.marker_symbol
    EOF

    sql
  end

  def _mi_plan_summary_cmg()

    sql = <<-EOF
    WITH intermediate_report AS (#{IntermediateReportSummaryByGene.select_sql(category = 'all', approach = 'all')})

    SELECT genes.marker_symbol, 
           genes.mgi_accession_id, 
           count(*) as number_of_notifications, 
           gpa.idg, 
           gpa.cmg_tier1, 
           gpa.cmg_tier2,
           intermediate_report.overall_status AS status
    FROM genes
      JOIN gene_private_annotations gpa ON gpa.gene_id = genes.id AND (gpa.cmg_tier1 = true OR gpa.cmg_tier2 = true)
      LEFT JOIN (notifications JOIN contacts ON contacts.id = notifications.contact_id AND contacts.report_to_public is true) ON genes.id = notifications.gene_id
      LEFT JOIN intermediate_report ON intermediate_report.gene = genes.marker_symbol
    GROUP BY genes.marker_symbol, genes.mgi_accession_id, gpa.idg, gpa.cmg_tier1, gpa.cmg_tier2, intermediate_report.overall_status
    ORDER BY genes.marker_symbol
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
      WITH intermediate_report AS (#{intermediate_table.select_sql(category = 'es cell', approach = 'all')})

      SELECT
        genes.marker_symbol,
        count(*) as number_of_notifications,
        gpa.idg,
        gpa.cmg_tier1,
        gpa.cmg_tier2,
        genes.marker_symbol as marker_symbol,
        genes.mgi_accession_id AS mgi_accession_id,
        intermediate_report.overall_status AS status
      FROM notifications
        JOIN contacts ON contacts.id = notifications.contact_id and contacts.report_to_public is true
        JOIN genes ON genes.id = notifications.gene_id
        JOIN gene_private_annotations gpa ON gpa.gene_id = genes.id
        LEFT JOIN intermediate_report ON intermediate_report.gene = genes.marker_symbol
        #{where_clause}
      GROUP BY genes.marker_symbol, genes.mgi_accession_id, gpa.idg, gpa.cmg_tier1, gpa.cmg_tier2, intermediate_report.overall_status
      ORDER BY number_of_notifications desc, marker_symbol, intermediate_report.overall_status
    EOF

    sql
  end
end
