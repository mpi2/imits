# encoding: utf-8

class Reports::MiProduction::SummaryKomp2

  extend Reports::MiProduction::SummariesCommon

  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS  
  DEBUG = Reports::MiProduction::SummariesCommon::DEBUG
  MAPPING_SUMMARIES = Reports::MiProduction::SummariesCommon::MAPPING_SUMMARIES
  ORDER_BY_MAP = Reports::MiProduction::SummariesCommon::ORDER_BY_MAP
  CONSORTIA_SUMMARY5 = ['BaSH', 'DTCC', 'JAX']

  def self.generate_short(request = nil, params={})
  
    script_name = request ? request.env['REQUEST_URI'] : ''
  
    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table
      
    #TODO: fix 'all' column
     
    array = []
   
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Production Centre' ] )
      
    summary = grouped_report.summary(
      'Consortium',
      'All'             => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['All'].include? row.data['Overall Status'] } ) },
      'ES QC started'   => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC started'].include? row.data['Overall Status'] } ) },
      'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC confirmed'].include? row.data['Overall Status'] } ) },
      'ES QC failed'    => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status'] } ) }
    )
      
    summary.each do |row|
  
      next if ! CONSORTIA_SUMMARY5.include?(row['Consortium'])
        
      summary2 = grouped_report.subgrouping(row['Consortium']).summary(
        'Production Centre',
        'MI in progress'  => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['MI in progress'].include? row.data['Overall Status'] } ) },
        'Genotype Confirmed Mice'       => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['Genotype Confirmed Mice'].include? row.data['Overall Status'] } ) },
        'MI Aborted'      => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['MI Aborted'].include? row.data['Overall Status'] } ) },
        'Languishing'        => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| languishing(row) } ) }
      )
  
      #make_link3 = lambda {|rowx, key|
      #  return rowx[key] if request && request.format == :csv
      #  consort = CGI.escape row['Consortium']
      #  pcentre = rowx['Production Centre'] ? CGI.escape(rowx['Production Centre']) : nil
      #  pcentre = pcentre ? "&pcentre=#{pcentre}" : ''
      #  type = CGI.escape key
      #  id = (consort + '_' + type + '_').gsub(/\-|\+|\s+/, "_").downcase
      #  rowx[key].to_s != '0' ?
      #    "<a title='Click to see list of #{key}' id='#{id}' href='#{script_name}?consortium=#{consort}#{pcentre}&type=#{type}'>#{rowx[key]}</a>" :
      #    ''
      #}
  
      hash = {
        'Consortium' => row['Consortium'],
        'All' => row['All'],
        'ES QC started' => row['ES QC started'],
        'ES QC confirmed' => row['ES QC confirmed'],
        'ES QC failed' => row['ES QC failed'],
        'array' => []
      }
  
      summary2.each do |row2|
  
        pc = efficiency(request, row2)
                
        pcentre = row2['Production Centre'] && row2['Production Centre'].length > 1 ? row2['Production Centre'] : '&nbsp;'
      
        hash2 = {
          'Production Centre' => pcentre,
          'MI in progress' => row2['MI in progress'],
          'Chimaeras' => '',
          'MI Aborted' => row2['MI Aborted'],
          'Genotype Confirmed Mice' => row2['Genotype Confirmed Mice'],
          'Pipeline efficiency (%)' => pc,
          'Registered for Phenotyping' => ''
        }
      
        hash['array'].push hash2
      
        array.push hash
       
      end
  
    end
  
    return array
  end

  def self.generate_new(request = nil, params={})
  
    if params[:consortium]
      title, report = subsummary_common(request, params)
      return title, report.to_html
    end

    report = generate6short(request, params)

    heading = ['Consortium', 'All', 'ES QC started', 'ES QC confirmed', 'ES QC failed',
      'Production Centre', 'MI in progress', 'Chimaeras', 'MI Aborted', 'Genotype Confirmed Mice', 'Pipeline efficiency (%)',
      'Registered for Phenotyping'
    ]

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

    table = '<table>'
    table += '<tr>'
    heading.each { |item| table += "<th>#{item}</th>"}
    table += '</tr>'

    report.each { |row| 
      table += '<tr>'
      table += "<td rowspan='SWAPME'>#{row['Consortium']}</td>"
      table += "<td rowspan='SWAPME'>#{make_link3.call(row, 'All')}</td>"
      table += "<td rowspan='SWAPME'>#{make_link3.call(row, 'ES QC started')}</td>"
      table += "<td rowspan='SWAPME'>#{make_link3.call(row, 'ES QC confirmed')}</td>"
      table += "<td rowspan='SWAPME'>#{make_link3.call(row, 'ES QC failed')}</td>"
      report['array'].each { |row2|
        table += "<td>#{pcentre}</td>"
        table += "<td>#{make_link3.call(row2, 'MI in progress')}</td>"
        table += "<td></td>"
        table += "<td>#{make_link3.call(row2, 'MI Aborted')}</td>"
        table += "<td>#{make_link3.call(row2, 'Genotype Confirmed Mice')}</td>"
        table += "<td>#{pc}</td>"
        table += "<td></td>"

        table += "<td>#{make_link3.call(row2, 'Languishing')}</td>" if DEBUG
 
        table += "</tr>"
      }
      table = table.gsub(/SWAPME/, pcentres.size.to_s)    
    }

    table += '</table>'

    return 'Production Summary 6', table
  
  end
  
  def self.all(row)
    return true
  end
  
  def self.generate(request = nil, params={})
    
    #  thing = generate6short(request, params)
    #   raise thing.inspect

    if params[:consortium]
      title, report = subsummary_common(request, params)
      return title, report.to_html
    end

    script_name = request ? request.env['REQUEST_URI'] : ''

    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table
    
    #TODO: fix 'all' column
    
    heading = ['Consortium', 'All', 'ES QC started', 'ES QC confirmed', 'ES QC failed',
      'Production Centre', 'MI in progress', 'Chimaeras', 'MI Aborted', 'Genotype Confirmed Mice', 'Pipeline efficiency (%)',
      'Registered for Phenotyping'
    ]

    heading.push 'Languishing' if DEBUG
    
    report_table = Table(heading)
 
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Production Centre' ] )
    
    summary = grouped_report.summary(
      'Consortium',
      #'All'             => lambda { |group| count_instances_of( group, 'Gene',
      #    lambda { |row| MAPPING_SUMMARIES['All'].include? row.data['Overall Status'] } ) },
      'All'             => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| all(row) } ) },
      'ES QC started'   => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC started'].include? row.data['Overall Status'] } ) },
      'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC confirmed'].include? row.data['Overall Status'] } ) },
      'ES QC failed'    => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status'] } ) }
    )

    table = '<table>'
    table += '<tr>'
    heading.each { |item|
      if item == 'All'
        table += "<th>All Genes</th>"
      else
        table += "<th>#{item}</th>"
      end      
    }
    table += '</tr>'
    
    summary.each do |row|

      next if ! CONSORTIA_SUMMARY5.include?(row['Consortium'])
      
      table += "<tr>"

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
      table += "<td rowspan='SWAPME'>#{row['Consortium']}</td>"
      table += "<td rowspan='SWAPME'>#{make_link3.call(row, 'All')}</td>"
      table += "<td rowspan='SWAPME'>#{make_link3.call(row, 'ES QC started')}</td>"
      table += "<td rowspan='SWAPME'>#{make_link3.call(row, 'ES QC confirmed')}</td>"
      table += "<td rowspan='SWAPME'>#{make_link3.call(row, 'ES QC failed')}</td>"

      pcentres = []

      summary2.each do |row2|

        pc = efficiency(request, row2)
  
        pcentres.push row2['Production Centre']
        
        pcentre = row2['Production Centre'] && row2['Production Centre'].length > 1 ? row2['Production Centre'] : '&nbsp;'

        table += "<td>#{pcentre}</td>"
        table += "<td>#{make_link3.call(row2, 'MI in progress')}</td>"
        table += "<td></td>"
        table += "<td>#{make_link3.call(row2, 'MI Aborted')}</td>"
        table += "<td>#{make_link3.call(row2, 'Genotype Confirmed Mice')}</td>"
        table += "<td>#{pc}</td>"
        
#        rfp = row2['Registered for Phenotyping'] && row2['Registered for Phenotyping'].to_s.length > 0 ? #&& row2['Registered for Phenotyping'] != 0 ?
#        row2['Registered for Phenotyping'] : ''
#        
##        rfp = rfp == '0' ? '' : rfp
#        rfp = rfp.to_s == '0' ? '' : rfp
#        
#        table += "<td>#{rfp}</td>"
        
        table += "<td>#{make_link3.call(row2, 'Registered for Phenotyping')}</td>"

        table += "<td>#{make_link3.call(row2, 'Languishing')}</td>" if DEBUG
 
        table += "</tr>"
     
      end
     
      table = table.gsub(/SWAPME/, pcentres.size.to_s)    
      
    end

    table += '</table>'

    return 'Production Summary 6', table
  end
  
  def self.registered_for_phenotyping(row)
    row && row['PhenotypeAttempt Status'] && row['PhenotypeAttempt Status'].to_s.length > 1
  end
  
  def self.generate_csv(request = nil, params={})

    if params[:consortium]
      return subsummary_common(request, params)
    end

    script_name = request ? request.env['REQUEST_URI'] : ''

    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table
    
    #TODO: fix 'all' column
    
    heading = ['Consortium', 'All', 'ES QC started', 'ES QC confirmed', 'ES QC failed',
      'Production Centre', 'MI in progress', 'Chimaeras', 'MI Aborted', 'Genotype Confirmed Mice', 'Pipeline efficiency (%)',
      'Registered for Phenotyping'
    ]

    report_table = Table(heading)
 
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Production Centre' ] )
    
    summary = grouped_report.summary(
      'Consortium',
      'All'             => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['All'].include? row.data['Overall Status'] } ) },
      'ES QC started'   => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC started'].include? row.data['Overall Status'] } ) },
      'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC confirmed'].include? row.data['Overall Status'] } ) },
      'ES QC failed'    => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status'] } ) }
    )

    summary.each do |row|

      next if ! CONSORTIA_SUMMARY5.include?(row['Consortium'])

      summary2 = grouped_report.subgrouping(row['Consortium']).summary(
        'Production Centre',
        'MI in progress'  => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['MI in progress'].include? row.data['Overall Status'] } ) },
        'Genotype Confirmed Mice'       => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['Genotype Confirmed Mice'].include? row.data['Overall Status'] } ) },
        'MI Aborted'      => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['MI Aborted'].include? row.data['Overall Status'] } ) },
        'Languishing'        => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| languishing(row) } ) }
      )

      #      make_link = lambda {|rowx, key, pcentre=nil|
      make_link = lambda {|rowx, key|
        return rowx[key] if request && request.format == :csv
        consort = CGI.escape row['Consortium']
        type = CGI.escape key
        id = (consort + '_' + type + '_').gsub(/\-|\+|\s+/, "_").downcase
        rowx[key].to_s != '0' ?
          "<a title='Click to see list of #{key}' id='#{id}' href='#{script_name}?consortium=#{consort}&type=#{type}'>#{rowx[key]}</a>" :
          ''
      }
      
      make_link2 = lambda {|rowx, key|
        return rowx[key] if request && request.format == :csv
        consort = CGI.escape row['Consortium']
        pcentre = CGI.escape rowx['Production Centre']
        type = CGI.escape key
        id = (consort + '_' + type + '_').gsub(/\-|\+|\s+/, "_").downcase
        rowx[key].to_s != '0' ?
          "<a title='Click to see list of #{key}' id='#{id}' href='#{script_name}?pcentre=#{pcentre}&consortium=#{consort}&type=#{type}'>#{rowx[key]}</a>" :
          ''
      }

      summary2.each do |row2|

        pc = efficiency(request, row2)
  
        report_table << {
          'Consortium' => row['Consortium'],
          'Production Centre' => row2['Production Centre'],
          'All' => make_link.call(row, 'All'),
          'ES QC started' => make_link.call(row, 'ES QC started'),
          'MI in progress' => make_link2.call(row2, 'MI in progress'),
          'Genotype Confirmed Mice' => make_link2.call(row2, 'Genotype Confirmed Mice'),
          'MI Aborted' => make_link2.call(row2, 'MI Aborted'),
          'Pipeline efficiency (%)' => pc,
          'ES QC confirmed' => make_link.call(row, 'ES QC confirmed'),
          'ES QC failed' => make_link.call(row, 'ES QC failed'),
          'Languishing' => make_link2.call(row2, 'Languishing')
        }
      
      end
      
    end

    return 'Production Summary 6', report_table
  end

end
