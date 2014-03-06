class NotificationsByGene < PlannedMicroinjectionList

  # dodgy use of temp tables
  # we're expecting to be run as a rake task to be cached

  def prepare_idg
    #sql = 'SET client_min_messages=WARNING;'
    #output = ActiveRecord::Base.connection.execute(sql)
    sql = 'SET client_min_messages=WARNING;drop table if exists tmp_idg_genes;'
    output = ActiveRecord::Base.connection.execute(sql)
    sql = 'SET client_min_messages=WARNING;drop table if exists tmp_idg_genes2;'
    output = ActiveRecord::Base.connection.execute(sql)

   # exit

    sql = <<-EOF
    create temporary table tmp_idg_genes as
    select marker_symbol, id, mgi_accession_id from genes where lower(genes.marker_symbol) in
    EOF

    config = YAML.load_file("#{Rails.root}/config/idg_symbols.yml")
    config = config.sort.uniq
    idg_clause = config.map {|i| "'#{i}'"} * ', '
    sql += " (#{idg_clause.downcase})"

    #puts "#### config.size: #{config.size}"
    # puts "\n\n" + sql

    output = ActiveRecord::Base.connection.execute(sql)
    #  pp output

    sql = <<-EOF
    create temporary table tmp_idg_genes2 (marker_symbol text, id int, mgi_accession_id int)
    EOF

    output = ActiveRecord::Base.connection.execute(sql)
    #  pp output

    sql = <<-EOF
    INSERT INTO tmp_idg_genes2 (marker_symbol, id, mgi_accession_id) values
    EOF

    sql_array = []

    config.each do |marker_symbol|
      sql_array.push "('#{marker_symbol}', -1, null)"
    end

    sql += sql_array.join ','

    output = ActiveRecord::Base.connection.execute(sql)
    #  pp output

    sql = <<-EOF
    INSERT INTO tmp_idg_genes (marker_symbol, id, mgi_accession_id)
    select marker_symbol, id, mgi_accession_id from tmp_idg_genes2
    where lower(marker_symbol) not in (select lower(marker_symbol) from tmp_idg_genes)
    EOF

    output = ActiveRecord::Base.connection.execute(sql)
    # pp output




    s = 'select count(*) as count from tmp_idg_genes'
    r = ActiveRecord::Base.connection.execute(s)
    #puts "#### count: #{r.first}"

    #s = 'select * from tmp_idg_genes'
    #r = ActiveRecord::Base.connection.execute(s)
    #puts "#### tmp_idg_genes:"
    #r.each do |row|
    #  puts "#{row["marker_symbol"]}"
    #end
    #
    #s = 'select * from tmp_idg_genes2'
    #r = ActiveRecord::Base.connection.execute(s)
    #puts "#### tmp_idg_genes2:"
    #r.each do |row|
    #  puts "#{row["marker_symbol"]}"
    #end




    #sql = <<-EOF
    #  insert into table tmp_idg_genes as
    #  select marker_symbol, id, mgi_accession_id from genes where lower(genes.marker_symbol) not in
    #EOF
  end

  def mi_plan_summary(production_centre = nil, consortium = nil, idg = false)

    #puts "#### mi_plan_summary: production_centre: #{production_centre}"
    #puts "#### mi_plan_summary: consortium: #{consortium}"

    if idg
      prepare_idg
      @mi_plan_summary = ActiveRecord::Base.connection.execute(self._mi_plan_summary_idg(production_centre, consortium))
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

  def pretty_print_statuses
    hash = {}
    @mi_plan_summary.each do |row|
      gene = Gene.find_by_marker_symbol(row['marker_symbol'])
      hash[row['marker_symbol']] = gene.relevant_status[:status].to_s.humanize.titleize if gene
    end
    hash
  end

  def _mi_plan_summary_idg(production_centre = nil, consortium = nil)
    where_clause = []
    where_clause.push "new_intermediate_report.consortium = '#{consortium}'" if consortium
    where_clause.push "new_intermediate_report.production_centre = '#{production_centre}'" if production_centre

    config = YAML.load_file("#{Rails.root}/config/idg_symbols.yml")
    idg_clause = config.map {|i| "'#{i}'"} * ', '
    idg_clause = "lower(new_intermediate_report.gene) in (#{idg_clause.downcase})"

    where_clause = ' where ' + where_clause.join(' and ') if where_clause.length > 0
    where_clause = '' if where_clause.length < 1

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

    #  puts "#### sql: #{sql}"

    sql
  end

  #def _mi_plan_summary_idg_old(production_centre = nil, consortium = nil)
  #  where_clause = []
  #  where_clause.push "new_intermediate_report.consortium = '#{consortium}'" if consortium
  #  where_clause.push "new_intermediate_report.production_centre = '#{production_centre}'" if production_centre
  #
  #  config = YAML.load_file("#{Rails.root}/config/idg_symbols.yml")
  #  idg_clause = config.map {|i| "'#{i}'"} * ', '
  #  idg_clause = "lower(new_intermediate_report.gene) in (#{idg_clause.downcase})"
  #
  #  where_clause = ' where ' + where_clause.join(' and ') if where_clause.length > 0
  #  where_clause = '' if where_clause.length < 1
  #
  #  sql = <<-EOF
  #  SELECT genes.marker_symbol, genes.mgi_accession_id, count(*) as total
  #  FROM notifications
  #  JOIN contacts ON contacts.id = notifications.contact_id and contacts.report_to_public is true
  #  JOIN genes ON genes.id = notifications.gene_id
  #  JOIN new_intermediate_report ON new_intermediate_report.gene = genes.marker_symbol or #{idg_clause}
  #  #{where_clause}
  #  GROUP BY genes.marker_symbol, genes.mgi_accession_id
  #  EOF
  #
  #  puts "#### sql: #{sql}"
  #
  #  sql
  #end

  def _mi_plan_summary(production_centre = nil, consortium = nil)
    where_clause = []

    #puts "#### _mi_plan_summary: consortium: #{consortium}"
    #puts "#### _mi_plan_summary: production_centre: #{production_centre}"

    where_clause.push "new_intermediate_report.consortium = '#{consortium}'" if consortium
    where_clause.push "new_intermediate_report.production_centre = '#{production_centre}'" if production_centre

    where_clause = 'where ' + where_clause.join(' and ') if where_clause.length > 0
    where_clause = '' if where_clause.length < 1

    #puts "#### _mi_plan_summary: where_clause: #{where_clause}"

    sql = <<-EOF
    SELECT
    genes.marker_symbol as gene,
    count(*) as number_of_notifications,
    genes.marker_symbol as marker_symbol,
    genes.mgi_accession_id AS mgi_accession_id
    FROM notifications
    JOIN contacts ON contacts.id = notifications.contact_id and contacts.report_to_public is true
    JOIN genes ON genes.id = notifications.gene_id
    LEFT JOIN new_intermediate_report ON new_intermediate_report.gene = genes.marker_symbol
    #{where_clause}
    GROUP BY genes.marker_symbol, genes.mgi_accession_id
    ORDER BY number_of_notifications desc, marker_symbol
    EOF

    # puts "#### _mi_plan_summary sql: #{sql}"

    sql
  end
end
