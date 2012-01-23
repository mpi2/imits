# encoding: utf-8

class Reports::MiProduction::SummaryByConsortium

  extend Reports::MiProduction::SummariesCommon

  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS  
  MAPPING_SUMMARIES = Reports::MiProduction::SummariesCommon::MAPPING_SUMMARIES
  PHENOTYPE_STATUSES = Reports::MiProduction::SummariesCommon::PHENOTYPE_STATUSES
  
  def self.generate(request = nil, params={}, consortia = nil, title = nil)
    
    title = title ? title : 'Summary By Consortium'

    debug = params['debug'] && params['debug'].to_s.length > 0

    if params[:consortium]
      return subsummary_common(params)
    end

    script_name = request ? request.env['REQUEST_URI'] : ''

    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table

    report_table = Table( ['Consortium', 'All', 'ES QC started', 'ES QC confirmed', 'ES QC failed',
        'MI in progress', 'MI Aborted', 'Genotype Confirmed Mice', 'Pipeline efficiency (%)', 'Languishing'] )
 
    grouped_report = Grouping( cached_report, :by => [ 'Consortium' ] )
    
    summary = grouped_report.summary(
      'Consortium',
      'All'             => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| all(row) } ) },
      'ES QC started'   => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC started'].include? row.data['Overall Status'] } ) },
      'MI in progress'  => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['MI in progress'].include? row.data['Overall Status'] } ) },
      'Genotype Confirmed Mice'       => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['Genotype Confirmed Mice'].include? row.data['Overall Status'] } ) },
      'MI Aborted'      => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['MI Aborted'].include? row.data['Overall Status'] } ) },
      'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC confirmed'].include? row.data['Overall Status'] } ) },
      'ES QC failed'    => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status'] } ) },
      'Languishing'        => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| languishing(row) } ) },
      'Phenotyped Count'        => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| PHENOTYPE_STATUSES.include? row.data['Overall Status'] } ) }
    )

    summary.each do |row|

      next if consortia && ! consortia.include?(row['Consortium'])

      make_link = lambda {|key|
        return row[key] if request && request.format == :csv
        consort = CGI.escape row['Consortium']
        type = CGI.escape key
        id = (consort + '_' + type + '_').gsub(/\-|\+|\s+/, "_").downcase
        separator = /\?/.match(script_name) ? '&' : '?'
        row[key].to_s != '0' ?
          "<a title='Click to see list of #{key}' id='#{id}' href='#{script_name}#{separator}consortium=#{consort}&type=#{type}'>#{row[key]}</a>" :
          ''
      }

      pc = efficiency(request, row)

      report_table << {
        'Consortium' => row['Consortium'],
        'Priority' => row['Priority'],
        'All' => make_link.call('All'),
        'ES QC started' => make_link.call('ES QC started'),
        'MI in progress' => make_link.call('MI in progress'),
        'Genotype Confirmed Mice' => make_link.call('Genotype Confirmed Mice'),
        'MI Aborted' => make_link.call('MI Aborted'),
        'Pipeline efficiency (%)' => pc,
        'ES QC confirmed' => make_link.call('ES QC confirmed'),
        'ES QC failed' => make_link.call('ES QC failed'),
        'Languishing' => make_link.call('Languishing')
      }
      
    end
    
    report_table.remove_column 'Languishing' if ! debug
  
    report_table.sort_rows_by!( ['Consortium'] )    
        
    return title, report_table
  end

end
