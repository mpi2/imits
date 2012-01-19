# encoding: utf-8

class Reports::MiProduction::SummaryKomp22

  extend Reports::MiProduction::SummariesCommon

  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS
  MAPPING_SUMMARIES = Reports::MiProduction::SummariesCommon::MAPPING_SUMMARIES
  CONSORTIA = ['BaSH', 'DTCC', 'JAX']
  REPORT_TITLE = "KOMP2 Report''"
  PHENOTYPE_STATUSES = Reports::MiProduction::SummariesCommon::PHENOTYPE_STATUSES

  HEADINGS = ['Consortium', 'All Genes', 'ES QC started', 'ES QC confirmed', 'ES QC failed',
    'Production Centre', 'MI in progress', 'Chimaeras', 'MI Aborted', 'Genotype Confirmed Mice',
    'Registered for Phenotyping'
  ]

  #def self.generate_csv(request = nil, params={})
  #
  #  debug = params['debug'] && params['debug'].to_s.length > 0
  #
  #  cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table
  #
  #  heading = HEADINGS
  #
  #  report_table = Table(heading)
  #
  #  grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Production Centre' ] )
  #
  #  grouped_report.each do |consortium|
  #
  #    next if ! CONSORTIA.include?(consortium)
  #
  #    summary2 = grouped_report.subgrouping(consortium).summary(
  #      'Production Centre',
  #      'MI in progress' => lambda { |group| count_instances_of( group, 'Gene',
  #          lambda { |row| MAPPING_SUMMARIES['MI in progress'].include? row.data['Overall Status'] } ) },
  #      'Genotype Confirmed Mice' => lambda { |group| count_instances_of( group, 'Gene',
  #          lambda { |row| MAPPING_SUMMARIES['Genotype Confirmed Mice'].include? row.data['Overall Status'] } ) },
  #      'MI Aborted' => lambda { |group| count_instances_of( group, 'Gene',
  #          lambda { |row| MAPPING_SUMMARIES['MI Aborted'].include? row.data['Overall Status'] } ) },
  #      'All Genes' => lambda { |group| count_instances_of( group, 'Gene',
  #          lambda { |row| all(row) } ) },
  #      'ES QC started' => lambda { |group| count_instances_of( group, 'Gene',
  #          lambda { |row| MAPPING_SUMMARIES['ES QC started'].include? row.data['Overall Status'] } ) },
  #      'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
  #          lambda { |row| MAPPING_SUMMARIES['ES QC confirmed'].include? row.data['Overall Status'] } ) },
  #      'ES QC failed' => lambda { |group| count_instances_of( group, 'Gene',
  #          lambda { |row| MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status'] } ) },
  #      'Registered for Phenotyping'        => lambda { |group| count_instances_of( group, 'Gene',
  #          lambda { |row| registered_for_phenotyping(row) } ) },
  #      'Phenotyped Count'        => lambda { |group| count_instances_of( group, 'Gene',
  #          lambda { |row| PHENOTYPE_STATUSES.include? row.data['Overall Status'] } ) }
  #    )
  #
  #    summary2.each do |row2|
  #
  #      pcentre = row2['Production Centre'] && row2['Production Centre'].length > 1 ? row2['Production Centre'] : ''
  #
  #      report_table << {
  #        'Consortium' => consortium,
  #        'Production Centre' => pcentre,
  #        'MI in progress' => row2['MI in progress'],
  #        'Genotype Confirmed Mice' => row2['Genotype Confirmed Mice'],
  #        'MI Aborted' => row2['MI Aborted'],
  #        'All Genes' => row2['All Genes'],
  #        'ES QC started' => row2['ES QC started'],
  #        'ES QC confirmed' => row2['ES QC confirmed'],
  #        'Registered for Phenotyping' => row2['Registered for Phenotyping'],
  #        'ES QC failed' => row2['ES QC failed']
  #      }
  #
  #    end
  #
  #  end
  #
  #  return REPORT_TITLE, report_table.to_csv
  #end

  def self.generate(request = nil, params={})

    if params[:consortium]
      title, report = subsummary_common(params)
      rv = request && request.format == :csv ? report.to_csv : report.to_html
      return title, rv
    end

    debug = params['debug'] && params['debug'].to_s.length > 0

    return generate_csv(request, params) if request && request.format == :csv

    script_name = request ? request.env['REQUEST_URI'] : ''

    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table

    heading = HEADINGS

    report_table = Table(heading)

    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Production Centre' ] )

    summary = grouped_report.summary(
      'Consortium',
      'All' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| all(row) } ) },
      'ES QC started' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| generic(row, 'ES QC started') } ) },
      'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| generic(row, 'ES QC confirmed') } ) },
      'ES QC failed' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| generic(row, 'ES QC failed') } ) }
    )

    table = '<table>'
    table += '<tr>'
    heading.each { |item| table += "<th>#{item}</th>" }
    table += '</tr>'

    summary.each do |row|

      next if ! CONSORTIA.include?(row['Consortium'])

      table += "<tr>"

      summary2 = grouped_report.subgrouping(row['Consortium']).summary(
        'Production Centre',
        'MI in progress' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| generic(row2, 'MI in progress') } ) },
        'Genotype Confirmed Mice' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| genotype_confirmed_mice(row2) } ) },
        'MI Aborted' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| mi_aborted(row2) } ) },
        'Registered for Phenotyping' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| registered_for_phenotyping(row2) } ) }
      )

      make_link = lambda {|rowx, key|
        return rowx[key] if request && request.format == :csv
        consort = CGI.escape row['Consortium']
        pcentre = rowx['Production Centre'] ? CGI.escape(rowx['Production Centre']) : nil
        pcentre = pcentre ? "&pcentre=#{pcentre}" : ''
        type = CGI.escape key
        id = (consort + '_' + type + '_').gsub(/\-|\+|\s+/, "_").downcase
        separator = /\?/.match(script_name) ? '&' : '?'
        rowx[key].to_s != '0' ?
          "<a title='Click to see list of #{key}' id='#{id}' href='#{script_name}#{separator}consortium=#{consort}#{pcentre}&type=#{type}'>#{rowx[key]}</a>" :
          ''
      }

      table += '<tr>'
      table += "<td rowspan='ROWSPANTARGET'>#{row['Consortium']}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'All')}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'ES QC started')}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'ES QC confirmed')}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'ES QC failed')}</td>"

      summary2.each do |row2|

        pcentre = row2['Production Centre'] && row2['Production Centre'].length > 1 ? row2['Production Centre'] : '&nbsp;'

        table += "<td>#{pcentre}</td>"
        table += "<td>#{make_link.call(row2, 'MI in progress')}</td>"
        table += "<td></td>"
        table += "<td>#{make_link.call(row2, 'MI Aborted')}</td>"
        table += "<td>#{make_link.call(row2, 'Genotype Confirmed Mice')}</td>"
        table += "<td>#{make_link.call(row2, 'Registered for Phenotyping')}</td>"
        table += "</tr>"

      end

      table = table.gsub(/ROWSPANTARGET/, summary2.size.to_s)

    end

    table += '</table>'

    return REPORT_TITLE, table
  end

  #MAPPING_SUMMARIES = {
  #  'All' => [],
  #  'ES QC started' => ['Assigned - ES Cell QC In Progress'],
  #  'MI in progress' => ['Micro-injection in progress'],
  #  'Genotype Confirmed Mice' => ['Genotype confirmed'],
  #  'MI Aborted' => ['Micro-injection aborted'],
  #  'ES QC confirmed' => ['Assigned - ES Cell QC Complete'],
  #  'ES QC failed' => ['Aborted - ES Cell QC Failed'],
  #  'Registered for Phenotyping' => ['Phenotype Attempt Registered']
  #}

  def self.all(row)
    return true
  end

  def self.generic(row, key)
    return false if !MAPPING_SUMMARIES[key].include? row.data[key]
    return check_date(row, key)
  end

  def self.check_date(row, key)
    first_day = Date.today << 1
    first_day = Time.new(first_day.year,first_day.month,1).to_date
    last_day = (Date.today << 1).end_of_month
    #return false if !MAPPING_SUMMARIES[key].include? row.data['Overall Status']
    #Assigned - ES Cell QC In Progress Date
    array = MAPPING_SUMMARIES[key]
    array.each do |item|
      item += ' Date'
      #day = row[item] ?
      next if ! row[item]
      splits = row[item].to_s.split(/\-/)
      next if ! splits
#raise splits.inspect
      day = Time.new(splits[0],splits[1],splits[2]).to_date
      #day << 1
      return true if day && day >= first_day && day <= last_day
    end
    return false
  end
  
  def self.es_qc_started(row)
    return false if !MAPPING_SUMMARIES['ES QC started'].include? row.data['Overall Status']
    #Assigned - ES Cell QC In Progress Date
    #array = MAPPING_SUMMARIES['ES QC started']
    return check_date(row, 'ES QC started')
  end

  def self.es_qc_confirmed(row)
    return false if ! MAPPING_SUMMARIES['ES QC confirmed'].include? row.data['Overall Status']
    return true
  end
  def self.es_qc_failed(row)
    return false if ! MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status']
    return true
  end
  def self.mi_in_progress(row)
    return false if ! MAPPING_SUMMARIES['MI in progress'].include? row.data['Overall Status']
    return true
  end
  def self.genotype_confirmed_mice(row)
    return false if ! MAPPING_SUMMARIES['Genotype Confirmed Mice'].include? row.data['Overall Status']
    return true
  end
  def self.mi_aborted(row)
    return false if ! MAPPING_SUMMARIES['MI Aborted'].include? row.data['Overall Status']
    return true
  end
  def self.registered_for_phenotyping(row)
    row && row['PhenotypeAttempt Status'] && row['PhenotypeAttempt Status'].to_s.length > 1
  end

end
