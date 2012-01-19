# encoding: utf-8

class Reports::MiProduction::SummaryByConsortiumPriority

  extend Reports::MiProduction::SummariesCommon

  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS  
  MAPPING_SUMMARIES = Reports::MiProduction::SummariesCommon::MAPPING_SUMMARIES
  ORDER_BY_MAP = Reports::MiProduction::SummariesCommon::ORDER_BY_MAP

  def self.generate(request = nil, params={})

    if params[:consortium]
      return subsummary_common(request, params)
    end

    script_name = request ? request.env['REQUEST_URI'] : ''
    debug = params['debug'] && params['debug'].to_s.length > 0

    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table

    report_table = Table( ['Consortium', 'Priority', 'All', 'ES QC started', 'ES QC failed', 'ES QC confirmed', 'MI in progress', 'MI Aborted', 'Genotype Confirmed Mice', 'Pipeline efficiency (%)', 'order_by', 'Languishing'] )
 
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Priority' ] )
    
    grouped_report.each do |consortium|
        
      summary = grouped_report.subgrouping(consortium).summary(
        'Priority',
        'All'            => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| all(row) } ) },
        'ES QC started'  => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['ES QC started'].include? row.data['Overall Status'] } ) },
        'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['ES QC confirmed'].include? row.data['Overall Status'] } ) },
        'MI in progress' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['MI in progress'].include? row.data['Overall Status'] } ) },
        'Genotype Confirmed Mice'       => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['Genotype Confirmed Mice'].include? row.data['Overall Status'] } ) },
        'MI Aborted'       => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['MI Aborted'].include? row.data['Overall Status'] } ) },
        'ES QC failed'       => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status'] } ) },
        'Languishing'        => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| languishing(row) } ) },
        'Phenotyped Count'        => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| PHENOTYPE_STATUSES.include? row.data['Overall Status'] } ) }
      )
      
      summary.each do |row|
        
        make_link = lambda {|key|
          return row[key] if request && request.format == :csv
          consort = CGI.escape consortium
          type = CGI.escape key
          priority = CGI.escape row['Priority']
          id = (consort + '_' + type + '_' + priority).gsub(/\-|\+|\s+/, "_").downcase
          separator = /\?/.match(script_name) ? '&' : '?'
          row[key].to_s != '0' ?
            "<a title='Click to see list of #{key}' id='#{id}' href='#{script_name}#{separator}consortium=#{consort}&type=#{key}&priority=#{priority}'>#{row[key]}</a>" :
            ''
        }

        pc = efficiency(request, row)
  
        report_table << {
          'Consortium' => consortium,
          'Priority' => row['Priority'],
          'All' => make_link.call('All'),
          'ES QC started' => make_link.call('ES QC started'),
          'ES QC confirmed' => make_link.call('ES QC confirmed'),
          'MI in progress' => make_link.call('MI in progress'),
          'Genotype Confirmed Mice' => make_link.call('Genotype Confirmed Mice'),
          'MI Aborted' => make_link.call('MI Aborted'),
          'Pipeline efficiency (%)' => pc,
          'order_by' => ORDER_BY_MAP[row['Priority']],
          'ES QC failed' => make_link.call('ES QC failed'),
          'Languishing' => make_link.call('Languishing')
        }
      end
      
    end

    report_table.remove_column 'Languishing' if ! debug
  
    report_table.sort_rows_by!( ['Consortium', 'order_by'] )    
    report_table.remove_column('order_by')
        
    return 'Summary By Consortium and Priority', report_table
  end

end
