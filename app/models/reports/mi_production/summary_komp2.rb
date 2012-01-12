# encoding: utf-8

class Reports::MiProduction::SummaryKomp2

  extend Reports::MiProduction::SummariesCommon

  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS  
  MAPPING_SUMMARIES = Reports::MiProduction::SummariesCommon::MAPPING_SUMMARIES
  ORDER_BY_MAP = Reports::MiProduction::SummariesCommon::ORDER_BY_MAP
  CONSORTIA = ['BaSH', 'DTCC', 'JAX']
  REPORT_TITLE = 'KOMP2 Report'

  HEADINGS = ['Consortium', 'All Genes', 'ES QC started', 'ES QC confirmed', 'ES QC failed',
    'Production Centre', 'MI in progress', 'Chimaeras', 'MI Aborted', 'Genotype Confirmed Mice', 'Pipeline efficiency (%)',
    'Registered for Phenotyping'
  ]

  def self.generate_short(request = nil, params={})
  
    script_name = request ? request.env['REQUEST_URI'] : ''
    debug = params['debug'] && params['debug'].to_s.length > 0
  
    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table

    array = []
   
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Production Centre' ] )
      
    summary = grouped_report.summary(
      'Consortium',
      'All Genes'             => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| all(row) } ) },
      'ES QC started'   => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC started'].include? row.data['Overall Status'] } ) },
      'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC confirmed'].include? row.data['Overall Status'] } ) },
      'ES QC failed'    => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status'] } ) }
    )
      
    summary.each do |row|
  
      next if ! CONSORTIA.include?(row['Consortium'])
        
      summary2 = grouped_report.subgrouping(row['Consortium']).summary(
        'Production Centre',
        'MI in progress'  => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['MI in progress'].include? row.data['Overall Status'] } ) },
        'Genotype Confirmed Mice'       => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['Genotype Confirmed Mice'].include? row.data['Overall Status'] } ) },
        'MI Aborted'      => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['MI Aborted'].include? row.data['Overall Status'] } ) },
        'Languishing'        => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| languishing(row) } ) },
        'Registered for Phenotyping'        => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| registered_for_phenotyping(row) } ) }
      )
  
      hash = {
        'Consortium' => row['Consortium'],
        'All Genes' => row['All Genes'],
        'ES QC started' => row['ES QC started'],
        'ES QC confirmed' => row['ES QC confirmed'],
        'ES QC failed' => row['ES QC failed'],
        'array' => []
      }
  
      summary2.each do |row2|
  
        pc = efficiency(request, row2)                
        pcentre = row2['Production Centre'] && row2['Production Centre'].length > 1 ? row2['Production Centre'] : ''
      
        hash2 = {
          'Production Centre' => pcentre,
          'MI in progress' => row2['MI in progress'],
          'Chimaeras' => '',
          'MI Aborted' => row2['MI Aborted'],
          'Genotype Confirmed Mice' => row2['Genotype Confirmed Mice'],
          'Pipeline efficiency (%)' => pc,
          'Registered for Phenotyping' => row2['Registered for Phenotyping'],
          'Languishing' => row2['Languishing'],
        }
      
        hash['array'].push hash2      
       
      end

      array.push hash
  
    end
  
    return array
  end

  def self.generate(request = nil, params={})
  
    if params[:consortium]
      title, report = subsummary_common(request, params)
      rv = request && request.format == :csv ? report.to_csv : report.to_html
      return title, rv
    end

    debug = params['debug'] && params['debug'].to_s.length > 0
    
    return generate_csv(request, params) if request && request.format == :csv    

    report = generate_short(request, params)

    script_name = request ? request.env['REQUEST_URI'] : ''
    
    heading = HEADINGS
   
    heading.push 'Languishing' if debug

    table = '<table>'
    table += '<tr>'
    heading.each { |item| table += "<th>#{item}</th>"}
    table += '</tr>'

    report.each { |row| 

      make_link3 = lambda {|rowx, key|
        return rowx[key] if request && request.format == :csv
        consort = CGI.escape row['Consortium']
        pcentre = rowx['Production Centre'] ? CGI.escape(rowx['Production Centre']) : nil
        pcentre = pcentre ? "&pcentre=#{pcentre}" : ''
        type = CGI.escape key
        id = (consort + '_' + type + '_').gsub(/\-|\+|\s+/, "_").downcase
        rowx[key].to_s != '0' ?
          "<a title='Click to see list of #{key}' id='#{id}' href='#{script_name}?consortium=#{consort}#{pcentre}&type=#{type}'>#{rowx[key]}</a>" :
          ''
      }

      table += '<tr>'
      table += "<td rowspan='ROWSPANTARGET'>#{row['Consortium']}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link3.call(row, 'All')}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link3.call(row, 'ES QC started')}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link3.call(row, 'ES QC confirmed')}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link3.call(row, 'ES QC failed')}</td>"
      
      row['array'].each { |row2|

        pcentre = row2['Production Centre'] && row2['Production Centre'].length > 1 ? row2['Production Centre'] : '&nbsp;'

        table += "<td>#{pcentre}</td>"
        table += "<td>#{make_link3.call(row2, 'MI in progress')}</td>"
        table += "<td></td>"
        table += "<td>#{make_link3.call(row2, 'MI Aborted')}</td>"
        table += "<td>#{make_link3.call(row2, 'Genotype Confirmed Mice')}</td>"
        table += "<td>#{row2['Pipeline efficiency (%)']}</td>"
        table += "<td>#{make_link3.call(row2, 'Registered for Phenotyping')}</td>"

        table += "<td>#{make_link3.call(row2, 'Languishing')}</td>" if debug
 
        table += "</tr>"
      }
      table = table.gsub(/ROWSPANTARGET/, row['array'].size.to_s)    
    }

    table += '</table>'

    return REPORT_TITLE, table
  
  end

  def self.registered_for_phenotyping(row)
    row && row['PhenotypeAttempt Status'] && row['PhenotypeAttempt Status'].to_s.length > 1
  end
  
  def self.quote(string)
    string = string.to_s.gsub(/\"/, '\"')
    return '"' + string.to_s + '"'
  end
  
  def self.generate_csv(request = nil, params={})
  
    if params[:consortium]
      title, report = subsummary_common(request, params)
      return title, report.to_html
    end

    debug = params['debug'] && params['debug'].to_s.length > 0

    report = generate_short(request, params)
   
    heading = HEADINGS
    heading.push 'Languishing' if debug

    table = ''
    heading.each { |item| table += quote(item) + ',' }
    table += "\n"

    report.each { |row| 
      
      row['array'].each { |row2|

        table += quote(row['Consortium']) + ','
        table += quote(row['All Genes']) + ','
        table += quote(row['ES QC started']) + ','
        table += quote(row['ES QC confirmed']) + ','
        table += quote(row['ES QC failed']) + ','

        table += quote(row2['Production Centre']) + ','
        table += quote(row2['MI in progress']) + ','
        table += quote('') + ','
        table += quote(row2['MI Aborted']) + ','
        table += quote(row2['Genotype Confirmed Mice']) + ','
        table += quote(row2['Pipeline efficiency (%)']) + ','
        table += quote(row2['Registered for Phenotyping'])
        table += ',' + quote(row2['Languishing']) if debug 
        table += "\n"
      }
    }

    return REPORT_TITLE, table
  
  end

end
