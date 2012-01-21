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
          lambda { |row| all(params, row) } ) },
      'ES QC started' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| generic(params, row, 'ES QC started') } ) },
      'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| generic(params, row, 'ES QC confirmed') } ) },
      'ES QC failed' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| generic(params, row, 'ES QC failed') } ) }
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
#            lambda { |row2| generic(params, row2, 'MI in progress') } ) },
          lambda { |row2| generic(params, row, 'MI in progress') } ) },
        'Genotype Confirmed Mice' => lambda { |group| count_instances_of( group, 'Gene',
#            lambda { |row2| generic(params, row2, 'Genotype Confirmed Mice') } ) },
          lambda { |row2| generic(params, row, 'Genotype Confirmed Mice') } ) },
        'MI Aborted' => lambda { |group| count_instances_of( group, 'Gene',
#            lambda { |row2| generic(params, row2, 'MI Aborted') } ) },
          lambda { |row2| generic(params, row, 'MI Aborted') } ) },
        'Registered for Phenotyping' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| generic(params, row2, 'Registered for Phenotyping') } ) }
#          lambda { |row2| generic(params, row, 'Registered for Phenotyping') } ) }
      )

      make_link = lambda {|rowx, key|
        return '' if rowx[key].to_s.length < 1
        return '' if rowx[key] == 0
        return rowx[key]
        #return rowx[key] if request && request.format == :csv
        #consort = CGI.escape row['Consortium']
        #pcentre = rowx['Production Centre'] ? CGI.escape(rowx['Production Centre']) : nil
        #pcentre = pcentre ? "&pcentre=#{pcentre}" : ''
        #type = CGI.escape key
        #id = (consort + '_' + type + '_').gsub(/\-|\+|\s+/, "_").downcase
        #separator = /\?/.match(script_name) ? '&' : '?'
        #rowx[key].to_s != '0' ?
        #  "<a title='Click to see list of #{key}' id='#{id}' href='#{script_name}#{separator}consortium=#{consort}#{pcentre}&type=#{type}'>#{rowx[key]}</a>" :
        #  ''
      }

      table += '<tr>'
      table += "<td rowspan='ROWSPANTARGET'>#{row['Consortium']}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'All')}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'ES QC started')}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'ES QC confirmed')}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'ES QC failed')}</td>"

      summary2.each do |row2|
        
        next if ! row2['Production Centre'] || row2['Production Centre'].length < 1

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
    
    months = params['months'] ? params['months'].to_i : 1
    month = get_month(months)
    report_title = REPORT_TITLE + " (#{month})"   # + " (#{months})"

    return report_title, table
  end

  def self.all(params, row)
    months = params['months'] ? params['months'].to_i : 1
    day = to_date(row.data['Overall Status'] + ' Date')
    first_day, last_day = get_first_and_last_days_of_month(months)
    return date_between(day, first_day, last_day)
  end

  def self.generic(params, row, key)
    return false if !MAPPING_SUMMARIES[key].include? row.data['Overall Status']
    return check_date(params, row, key)
  end
  
  def self.check_date(params, row, key)
    months = params['months'] ? params['months'].to_i : 1
    first_day, last_day = get_first_and_last_days_of_month(months)

    array = MAPPING_SUMMARIES[key]
    array.each do |item|
      day = to_date(row[item + ' Date'])
      return true if date_between(day, first_day, last_day)
    end

    return false
  end

  def self.get_first_and_last_days_of_month(month)
    first_day = Date.today << month
    first_day = Time.new(first_day.year,first_day.month,1).to_date
    last_day = (Date.today << month).end_of_month
    return first_day, last_day
  end
  
  def self.get_month(month)
    return "Unknown" if ! month || month < 0
    day = Date.today << month
    return Date::MONTHNAMES[day.month] 
  end

  def self.to_date(string)
    return nil if ! string || string.to_s.length < 1 || ! /-/.match(string)
    splits = string.to_s.split(/\-/)
     return nil if ! splits || splits.size < 3
    day = Time.new(splits[0],splits[1],splits[2])
    day = day ? day.to_date : nil
    return day
  end
  
  def self.date_between(target_date, start_date, end_date)
    return false if !target_date || !start_date || !end_date
    return target_date >= start_date && target_date <= end_date
  end
  
end
