# encoding: utf-8

class Reports::MiProduction::SummaryKomp2

  extend Reports::MiProduction::SummariesCommon

  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS  
  MAPPING_SUMMARIES = Reports::MiProduction::SummariesCommon::MAPPING_SUMMARIES
  CONSORTIA = ['BaSH', 'DTCC', 'JAX']
  REPORT_TITLE = 'KOMP2 Report'
  PHENOTYPE_STATUSES = Reports::MiProduction::SummariesCommon::PHENOTYPE_STATUSES

  HEADINGS = ['Consortium', 'All Genes', 'ES QC started', 'ES QC confirmed', 'ES QC failed',
    'Production Centre', 'MI in progress', 'Chimaeras', 'MI Aborted', 'Genotype Confirmed Mice', 'Pipeline efficiency (%)',
    'Pipeline efficiency (by clone)',
    'Registered for Phenotyping'
  ]

  def self.generate_csv(request = nil, params={})
  
    debug = params['debug'] && params['debug'].to_s.length > 0
  
    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table

    heading = HEADINGS

    heading.push 'Languishing' if debug
    heading.push 'Distinct Genotype Confirmed ES Cells' if debug
    heading.push 'Distinct Old Non Genotype Confirmed ES Cells' if debug
      
    report_table = Table(heading)
        
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Production Centre' ] )
      
    grouped_report.each do |consortium|
  
      next if ! CONSORTIA.include?(consortium)
        
      summary2 = grouped_report.subgrouping(consortium).summary(
        'Production Centre',
        'MI in progress' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['MI in progress'].include? row.data['Overall Status'] } ) },
        'Genotype Confirmed Mice' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| glt(row) } ) },
        'MI Aborted' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['MI Aborted'].include? row.data['Overall Status'] } ) },
        'Languishing' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| languishing(row) } ) },
        'All Genes' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| all(row) } ) },
        'ES QC started' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['ES QC started'].include? row.data['Overall Status'] } ) },
        'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['ES QC confirmed'].include? row.data['Overall Status'] } ) },
        'ES QC failed' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status'] } ) },
        'Registered for Phenotyping'        => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| registered_for_phenotyping(row) } ) },
        'Phenotyped Count'        => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| PHENOTYPE_STATUSES.include? row.data['Overall Status'] } ) }
      )

      summary2.each do |row2|
  
        pc = efficiency(request, row2)
        pc2 = efficiency2(request, row2)
                
        pcentre = row2['Production Centre'] && row2['Production Centre'].length > 1 ? row2['Production Centre'] : ''

        report_table << {
          'Consortium' => consortium,
          'Production Centre' => pcentre,
          'MI in progress' => row2['MI in progress'],
          'Genotype Confirmed Mice' => row2['Genotype Confirmed Mice'],
          'MI Aborted' => row2['MI Aborted'],
          'Languishing' => row2['Languishing'],
          'Languishing2' => row2['Languishing2'],
          'All Genes' => row2['All Genes'],
          'ES QC started' => row2['ES QC started'],
          'ES QC confirmed' => row2['ES QC confirmed'],
          'Registered for Phenotyping' => row2['Registered for Phenotyping'],
          'Pipeline efficiency (%)' => pc,
          'ES QC failed' => row2['ES QC failed'],
          'Pipeline efficiency (by clone)' => pc2,
          'Distinct Genotype Confirmed ES Cells' => lambda { |group| distinct_genotype_confirmed_es_cells(group) },
          'Distinct Old Non Genotype Confirmed ES Cells' => lambda { |group| distinct_old_non_genotype_confirmed_es_cells(group) }
        }
      
      end
  
    end
  
    return REPORT_TITLE, report_table.to_csv
  end

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
    heading.push 'Languishing' if debug
    heading.push 'Distinct Genotype Confirmed ES Cells' if debug
    heading.push 'Distinct Old Non Genotype Confirmed ES Cells' if debug
    
    report_table = Table(heading)
 
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Production Centre' ] )
    
    summary = grouped_report.summary(
      'Consortium',
      'All' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| all(row) } ) },
      'ES QC started' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC started'].include? row.data['Overall Status'] } ) },
      'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC confirmed'].include? row.data['Overall Status'] } ) },
      'ES QC failed' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status'] } ) }
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
            lambda { |row2| MAPPING_SUMMARIES['MI in progress'].include? row2.data['Overall Status'] } ) },
        'Genotype Confirmed Mice' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| glt(row2) } ) },
        'MI Aborted' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['MI Aborted'].include? row2.data['Overall Status'] } ) },
        'Languishing' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| languishing(row2) } ) },
        'Registered for Phenotyping' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| registered_for_phenotyping(row2) } ) },
        'Distinct Genotype Confirmed ES Cells' => lambda { |group| distinct_genotype_confirmed_es_cells(group) },
        'Distinct Old Non Genotype Confirmed ES Cells' => lambda { |group| distinct_old_non_genotype_confirmed_es_cells(group) }
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
      make_efficiency1 = lambda {|rowx, pc|
        return "<td>#{pc}</td>" if ! debug
        return "<td title='Calculated: glt / (glt + languishing) - #{rowx['Genotype Confirmed Mice']} / (#{rowx['Genotype Confirmed Mice']} + #{rowx['Languishing']})'>#{pc}</td>"
      }
      make_efficiency2 = lambda {|rowx, pc|
        return "<td>#{pc}</td>" if ! debug
        return "<td title='Calculated: Distinct Genotype Confirmed ES Cells / (Distinct Genotype Confirmed ES Cells + Distinct Old Non Genotype Confirmed ES Cells)" +
      " - #{rowx['Distinct Genotype Confirmed ES Cells']} / (#{rowx['Distinct Genotype Confirmed ES Cells']} + #{rowx['Distinct Old Non Genotype Confirmed ES Cells']})'>#{pc}</td>"
      }
      
      table += '<tr>'
      table += "<td rowspan='ROWSPANTARGET'>#{row['Consortium']}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'All')}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'ES QC started')}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'ES QC confirmed')}</td>"
      table += "<td rowspan='ROWSPANTARGET'>#{make_link.call(row, 'ES QC failed')}</td>"

#TODO: lose pcentres

      pcentres = []

      summary2.each do |row2|

        next if ! row2['Production Centre'] || row2['Production Centre'].length < 1

        pc = efficiency(request, row2)
        pc2 = efficiency2(request, row2)
  
        pcentres.push row2['Production Centre']
        
        pcentre = row2['Production Centre'] && row2['Production Centre'].length > 1 ? row2['Production Centre'] : '&nbsp;'

        table += "<td>#{pcentre}</td>"
        table += "<td>#{make_link.call(row2, 'MI in progress')}</td>"
        table += "<td></td>"
        table += "<td>#{make_link.call(row2, 'MI Aborted')}</td>"
        table += "<td>#{make_link.call(row2, 'Genotype Confirmed Mice')}</td>"
        table += make_efficiency1.call(row2, pc)
        table += make_efficiency2.call(row2, pc2)
        table += "<td>#{make_link.call(row2, 'Registered for Phenotyping')}</td>"
        table += "<td>#{make_link.call(row2, 'Languishing')}</td>" if debug 
        table += "<td>#{make_link.call(row2, 'Distinct Genotype Confirmed ES Cells')}</td>" if debug 
        table += "<td>#{make_link.call(row2, 'Distinct Old Non Genotype Confirmed ES Cells')}</td>" if debug 
        table += "</tr>"
     
      end
     
#      table = table.gsub(/ROWSPANTARGET/, pcentres.size.to_s)
      table = table.gsub(/ROWSPANTARGET/, summary2.size.to_s)
      
    end

    table += '</table>'

    return REPORT_TITLE, table
  end
  
end
