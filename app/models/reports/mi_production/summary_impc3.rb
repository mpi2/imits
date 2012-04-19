# encoding: utf-8

class Reports::MiProduction::SummaryImpc3 < Reports::Base

  extend Reports::MiProduction::SummariesCommon

  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS

  DEBUG_HEADINGS = [
    'Genotype confirmed mice 6 months',
    'Microinjection aborted 6 months',
    'Languishing',
    'Distinct Genotype Confirmed ES Cells',
    'Distinct Old Non Genotype Confirmed ES Cells'
  ]

  HEADINGS = [
    'Consortium',
    'Production Centre',
    'All genes',
    'ES QC failed',
    'ES QC confirmed',
    'ES cell QC',
    'Genotype confirmed mice',
    'Microinjection aborted',
    'Microinjections',
    'Chimaeras produced',
    'Phenotyping aborted',
    'Phenotyping completed',
    'Phenotyping started',
    'Cre excision completed',
    'Cre excision started',
    'Rederivation started',
    'Rederivation completed',
    'Registered for phenotyping',

    'Gene Pipeline efficiency (%)',
    'Clone Pipeline efficiency (%)'
  ] + DEBUG_HEADINGS

  def self.report_title; 'Production for IMPC Consortia'; end
  def self.report_subsummary_title; 'Production Summary Detail'; end
  def self.consortia; @@all_consortia ||= Consortium.all.map(&:name); end

  def self.efficiency_6months(params, row)
    glt = row['Genotype confirmed mice 6 months'].to_i
    failures = row['Languishing'].to_i + row['Microinjection aborted 6 months'].to_i
    total = glt + failures
    pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
    pc = pc != 0 ? "%i" % pc : params[:format] != :csv ? '' : 0
    return pc
  end

  def self.efficiency_clone(params, row)
    a = row['Distinct Genotype Confirmed ES Cells'].to_i
    b = row['Distinct Old Non Genotype Confirmed ES Cells'].to_i
    pc =  a + b != 0 ? ((a.to_f / (a + b).to_f) * 100) : 0
    pc = pc != 0 ? "%i" % pc : params[:format] != :csv ? '' : 0
    return pc
  end

  def self.genotype_confirmed_6month(row)
    return false if row['Genotype confirmed Date'].blank?
    return Date.parse(row['Micro-injection in progress Date']) < 6.months.ago.to_date
  end

  def self.distinct_genotype_confirmed_es_cells_count(group)
    total = 0
    group.each { |row| total += row['Distinct Genotype Confirmed ES Cells'].to_i }
    return total
  end

  def self.distinct_old_non_genotype_confirmed_es_cells_count(group)
    total = 0
    group.each { |row| total += row['Distinct Old Non Genotype Confirmed ES Cells'].to_i }
    return total
  end

  def self.generate_common(params)

    debug = params['debug'] && params['debug'].to_s.length > 0
    pretty = params['pretty'] && params['pretty'].to_s.length > 0

    links = pretty ? false : links

    cached_report = ReportCache.find_by_name_and_format!(Reports::MiProduction::Intermediate.report_name, 'csv').to_table

    script_name = params[:script_name]

    heading = HEADINGS

    report_table = Table(heading)

    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Production Centre' ] )

    list_heads = [
      'ES QC confirmed',
      'Microinjection aborted',
      'Cre excision started',
      'Phenotyping completed',
      'Phenotyping aborted',
      'ES QC failed',
      'ES cell QC',
      'Genotype confirmed mice',
      'Microinjections',
      'Chimaeras produced',
      'Phenotyping started',
      'Cre excision completed',
      'Rederivation started',
      'Rederivation completed',
      'Registered for phenotyping',
      'Genotype confirmed mice 6 months',
      'Microinjection aborted 6 months',
      'Languishing'
    ]

    hash = {}
    hash['Distinct Genotype Confirmed ES Cells'] = lambda { |group| distinct_genotype_confirmed_es_cells_count(group) }
    hash['Distinct Old Non Genotype Confirmed ES Cells'] = lambda { |group| distinct_old_non_genotype_confirmed_es_cells_count(group) }
    hash['All genes'] = lambda { |group| count_unique_instances_of( group, 'Gene', lambda { |row| count_row(row, 'All genes') } ) }

    list_heads.each do |item|
      hash[item] = lambda { |group| count_instances_of( group, 'Gene', lambda { |row| count_row(row, item) } ) }
    end

    grouped_report.each do |consortium|

      next if ! consortia.include?(consortium)

      grouped_report.subgrouping(consortium).summary('Production Centre', hash).each do |row|

        row['Production Centre'] = '' if row['Production Centre'].to_s.length < 1

        pc = efficiency_6months(params, row)
        pc2 = efficiency_clone(params, row)

        make_clean = lambda {|value|
          return value if params[:format] == :csv
          return '' if ! value || value.to_s == "0"
          return value
        }

        make_link = lambda {|rowx, key|
          return rowx[key] if params[:format] == :csv
          return '' if rowx[key].to_s.length < 1
          return '' if rowx[key] == 0
          return rowx[key] if ! links

          consort = CGI.escape consortium
          pcentre = CGI.escape rowx['Production Centre']
          pcentre = pcentre ? "&pcentre=#{pcentre}" : ''
          type = CGI.escape key
          separator = /\?/.match(script_name) ? '&' : '?'
          return "<a title='Click to see list of #{key}' href='#{script_name}#{separator}consortium=#{consort}#{pcentre}&type=#{type}'>#{rowx[key]}</a>"
        }

        list_heads = [
          'All genes',
          'ES QC confirmed',
          'Microinjection aborted',
          'Languishing',
          'Distinct Genotype Confirmed ES Cells',
          'Distinct Old Non Genotype Confirmed ES Cells',
          'Cre Excision Started',
          'Cre excision completed',
          'Phenotyping completed',
          'Phenotyping aborted',
          'ES QC failed',
          'ES cell QC',
          'Genotype confirmed mice',
          'Microinjections',
          'Chimaeras produced',
          'Phenotyping started',
          'Rederivation started',
          'Cre excision started',
          'Rederivation completed',
          'Registered for phenotyping',
          'Genotype confirmed mice 6 months',
          'Microinjection aborted 6 months'
        ]

        new_hash = {}
        new_hash['Consortium'] = consortium
        next if ! row['Production Centre']
        new_hash['Production Centre'] = row['Production Centre']
        new_hash['Gene Pipeline efficiency (%)'] = make_clean.call(pc)
        new_hash['Clone Pipeline efficiency (%)'] = make_clean.call(pc2)
        list_heads.each do |item|
          new_hash[item] = make_link.call(row, item)
        end

        report_table << new_hash

      end
    end

    return report_table
  end

  def self.count_row(row, key)

    return true if key == 'All genes'

    if key == 'ES QC failed'
      return row['MiPlan Status'] == 'Aborted - ES Cell QC Failed'
    end

    if key == 'ES QC confirmed'
      return row['MiPlan Status'] == 'Assigned - ES Cell QC Complete'
    end

    if key == 'ES cell QC'
      return ['Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete', 'Aborted - ES Cell QC Failed'].include?(row['MiPlan Status'])
    end

    if key == 'Genotype confirmed mice'
      return row['MiAttempt Status'] == 'Genotype confirmed'
    end

    if key == 'Genotype confirmed mice 6 months'
      return row['MiAttempt Status'] == 'Genotype confirmed' && genotype_confirmed_6month(row)
    end

    if key == 'Microinjection aborted'
      return row['MiAttempt Status'] == 'Micro-injection aborted'
    end

    if key == 'Microinjection aborted 6 months'
      return row['MiAttempt Status'] == 'Micro-injection aborted' && Date.parse(row['Micro-injection aborted Date']) < 6.months.ago.to_date
    end

    if key == 'Microinjections'
      return row['MiAttempt Status'] == 'Micro-injection in progress' || row['MiAttempt Status'] == 'Genotype confirmed' ||
        row['MiAttempt Status'] == 'Micro-injection aborted' || row['MiAttempt Status'] == 'Chimeras obtained'
    end

    if key == 'Chimaeras produced'
      return row['MiAttempt Status'] == 'Chimeras obtained'
    end

    if key == 'Phenotyping aborted'
      return row['PhenotypeAttempt Status'] == 'Phenotype Attempt Aborted'
    end

    if key == 'Phenotyping completed'
      return row['PhenotypeAttempt Status'] == 'Phenotyping Complete'
    end

    if key == 'Phenotyping started'
      return row['PhenotypeAttempt Status'] == 'Phenotyping Started'
    end

    if key == 'Cre excision completed'
      return row['PhenotypeAttempt Status'] == 'Cre Excision Complete'
    end

    if key == 'Cre excision started'
      return row['PhenotypeAttempt Status'] == 'Cre Excision Started'
    end

    if key == 'Rederivation started'
      return row['PhenotypeAttempt Status'] == 'Rederivation started' && row['Rederivation Start Date'].to_s.length > 0
    end
    
    if key == 'Rederivation completed'
      return row['PhenotypeAttempt Status'] == 'Rederivation completed' && row['Rederivation Complete Date'].to_s.length > 0
    end
    
    valid_phenos = [
      'Phenotype Attempt Registered',
      'Rederivation Started',
      'Rederivation Complete',
      'Cre Excision Started',
      'Cre Excision Complete',
      'Phenotyping Started',
      'Phenotyping Complete'
    ]

    if key == 'Registered for phenotyping'
      return valid_phenos.include?(row['PhenotypeAttempt Status'])
    end

    if key == 'Distinct Genotype Confirmed ES Cells'
      return row[key] && row[key].to_s.length > 0
    end

    if key == 'Distinct Old Non Genotype Confirmed ES Cells'
      return row[key] && row[key].to_s.length > 0
    end

    if key == 'Languishing'
      return (row.data['Overall Status'] == 'Micro-injection in progress' || row.data['Overall Status'] == 'Chimeras obtained') &&
        Date.parse(row['Micro-injection in progress Date']) < 6.months.ago.to_date
    end

    return false

  end

  def self.subsummary(params)
    consortium = params[:consortium]
    type = params[:type]
    type = type ? type.gsub(/^\#\s+/, "") : nil
    priority = params[:priority]
    subproject = params[:subproject]

    pcentre = params[:pcentre]

    details = params['details'] && params['details'].to_s.length > 0

    cached_report = ReportCache.find_by_name_and_format!('mi_production_intermediate', 'csv').to_table

    report = Table(:data => cached_report.data,
      :column_names => cached_report.column_names,
      :filters => lambda {|r|

        return false if r['Consortium'] != consortium
        return false if pcentre && pcentre.to_s.length > 0 && r['Production Centre'] != pcentre

        return r[type] && r[type].to_s.length > 0 && r[type].to_i != 0 if type == 'Distinct Genotype Confirmed ES Cells'
        return r[type] && r[type].to_s.length > 0 && r[type].to_i != 0 if type == 'Distinct Old Non Genotype Confirmed ES Cells'

        return count_row(r, type)

      },
      :transforms => lambda {|r|
        r['Mutation Sub-Type'] = fix_mutation_type r['Mutation Sub-Type']
      }
    )

    exclude_columns = [
      "MiPlan Status",
      "MiAttempt Status",
      "PhenotypeAttempt Status"
    ]

    exclude_columns.each do |name|
      report.remove_column name
    end

    consortium = consortium ? "Consortium: '#{consortium}' - " : ''
    pcentre = pcentre ? "Centre: '#{pcentre}' - " : ''
    type = type ? "Type: '#{type}' - " : ''

    report.rename_column 'Overall Status', 'Status'
    report.rename_column 'Mutation Sub-Type', 'Mutation Type'

    if details
      title = "#{report_subsummary_title}: #{consortium}#{pcentre}#{type} (#{report.size})"
    else
      title = report_subsummary_title
    end

    return title, report
  end

  def self.generate(params = {})

    if params[:consortium]
      title, report = subsummary(params)
      rv = params[:format] == :csv ? report.to_csv : report.to_html
      #      return title, rv
      return { :title => title, :csv => report.to_csv, :html => report.to_html,
        :table => report  # for testing
      }
    end

    details = params['details'] && params['details'].to_s.length > 0
    do_table = params['table'] && params['table'].to_s.length > 0

    report = generate_common(params)

    new_columns = [
      "Consortium",
      "All genes",
      "ES cell QC",
      "ES QC confirmed",
      "ES QC failed",
      "Production Centre",
      "Microinjections",
      "Chimaeras produced",
      "Genotype confirmed mice",
      "Microinjection aborted",
      "Gene Pipeline efficiency (%)",
      "Clone Pipeline efficiency (%)",
      "Registered for phenotyping",
      "Rederivation started",
      "Rederivation completed",
      "Cre excision started",
      "Cre excision completed",
      "Phenotyping started",
      "Phenotyping completed",
      "Phenotyping aborted",
    ] + (details ? DEBUG_HEADINGS : [])

    report.reorder(new_columns)

    title = report_title

    return title, report if do_table

    html = prettify(params, report)
    return { :title => title, :csv => report.to_csv, :html => html, :table => report }

  end

  def self.prettify(params, table)

    script_name = params[:script_name]

    centres = {}
    sub_table = table.sub_table do |r|
      centres[r["Consortium"]] ||= []
      if r['Production Centre'].to_s.length > 0 && ! centres[r["Consortium"]].include?(r['Production Centre'])
        centres[r["Consortium"]].push r['Production Centre']
      end
    end

    summaries = {}
    grouped_report = Grouping( table, :by => [ 'Consortium' ] )
    labels = ['All genes', 'ES cell QC', 'ES QC confirmed', 'ES QC failed']

    grouped_report.each do |consortium|
      summaries[consortium] = {}
      labels.each { |item| summaries[consortium][item] = grouped_report[consortium].sigma(item) }
    end

    array = []
    array.push '<table>'
    array.push '<tr>'

    table.column_names.each { |name| array.push "<th>#{name}</th>" }

    other_columns = table.column_names - ["Consortium", "All genes", "ES cell QC", "ES QC confirmed",  "ES QC failed"]
    rows = table.data.size

    make_link = lambda {|value, consortium, pcentre, type|
      return '' if value.to_s.length < 1
      return '' if value == 0

      consortium = CGI.escape consortium
      pcentre = pcentre ? CGI.escape(pcentre) : ''
      type = CGI.escape type
      separator = /\?/.match(script_name) ? '&' : '?'
      return "<a href='#{script_name}#{separator}consortium=#{consortium}&pcentre=#{pcentre}&type=#{type}'>#{value}</a>"
    }

    grouped_report.each do |consortium_name1|
      array.push '</tr>'
      size = centres[consortium_name1].size.to_s
      array.push "<td rowspan='#{size}'>#{consortium_name1}</td>"
      array.push "<td rowspan='#{size}'>" + make_link.call(summaries[consortium_name1]['All genes'], consortium_name1, nil, 'All genes') + "</td>"
      array.push "<td rowspan='#{size}'>" + make_link.call(summaries[consortium_name1]['ES cell QC'], consortium_name1, nil, 'ES cell QC') + "</td>"
      array.push "<td rowspan='#{size}'>" + make_link.call(summaries[consortium_name1]['ES QC confirmed'], consortium_name1, nil, 'ES QC confirmed') + "</td>"
      array.push "<td rowspan='#{size}'>" + make_link.call(summaries[consortium_name1]['ES QC failed'], consortium_name1, nil, 'ES QC failed') + "</td>"

      i=0
      while i < rows

        # this is where we exclude Production Centres with empty names

        if table.column('Consortium')[i] != consortium_name1 || table.column('Production Centre')[i].to_s.length < 1
          i+=1
          next
        end

        ignore_columns = ['Production Centre', 'Gene Pipeline efficiency (%)', 'Clone Pipeline efficiency (%)']

        other_columns.each do |consortium_name2|
          array.push "<td>#{table.column(consortium_name2)[i]}</td>" if ignore_columns.include?(consortium_name2)
          next if ignore_columns.include?(consortium_name2)
          array.push("<td>" + make_link.call(table.column(consortium_name2)[i], consortium_name1, table.column('Production Centre')[i], consortium_name2) + "</td>")

        end

        array.push '</tr>'

        i+=1

      end

    end

    # HACKHACKHACKHACKHACKHACKHACKHACKHACKHACKHACKHACKHACKHACKHACKHACKHACK
    array.push '</table>'
    retval = array.join("\n")
    retval.gsub!(/Registered for phenotyping/i, 'Intent to phenotype')
    return retval
  end

  def self.report_name; 'production_summary_impc3'; end

  def initialize
    generated = self.class.generate
    @csv = generated[:csv]
    @html = generated[:html]
  end

  def to(format)
    if format == 'html'
      return @html
    elsif format == 'csv'
      return @csv
    end
  end
end
