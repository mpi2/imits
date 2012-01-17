# encoding: utf-8

class Reports::MiProduction::SummaryKomp21

  extend Reports::MiProduction::SummariesCommon

  CSV_LINKS = Reports::MiProduction::SummariesCommon::CSV_LINKS  
  MAPPING_SUMMARIES = Reports::MiProduction::SummariesCommon::MAPPING_SUMMARIES
  CONSORTIA = ['BaSH', 'DTCC', 'JAX']
  REPORT_TITLE = 'KOMP2 Report (1)'

  HEADINGS = ['Consortium', 'Production Centre', 'All', 'ES QC started', 'ES QC confirmed',
              'ES QC failed', 'MI in progress', 'Chimaeras', 'MI Aborted', 'Genotype Confirmed Mice',
              'Pipeline efficiency (%)',
              'Pipeline efficiency (by clone)',
              'Registered for Phenotyping'
            ]
  
  #TODO: fix efficiency names

  def self.generate(request = nil, params={})
    
    if params[:consortium]
      title, report = subsummary_common(request, params)
      return title, report
    end

    debug = params['debug'] && params['debug'].to_s.length > 0

    script_name = request ? request.env['REQUEST_URI'] : ''

    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table
        
    heading = HEADINGS   
    heading.push 'Languishing' if debug
    heading.push 'Distinct Genotype Confirmed ES Cells' if debug
    heading.push 'Distinct Old Non Genotype Confirmed ES Cells' if debug
    
    report_table = Table(heading)
 
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Production Centre' ] )
    
    grouped_report.each do |consortium| 

      next if ! CONSORTIA.include?(consortium)

      summary = grouped_report.subgrouping(consortium).summary(

        'Production Centre',
        'All' => lambda { |group| count_instances_of( group, 'Gene',
              lambda { |row| all(row) } ) },
        'ES QC started' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['ES QC started'].include? row.data['Overall Status'] } ) },
        'ES QC confirmed' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['ES QC confirmed'].include? row.data['Overall Status'] } ) },
        'ES QC failed' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status'] } ) },
        'MI in progress' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['MI in progress'].include? row2.data['Overall Status'] } ) },
        'Genotype Confirmed Mice' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['Genotype Confirmed Mice'].include? row2.data['Overall Status'] } ) },
        'MI Aborted' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| MAPPING_SUMMARIES['MI Aborted'].include? row2.data['Overall Status'] } ) },
        'Registered for Phenotyping' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| registered_for_phenotyping(row2) } ) },
        'Languishing' => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row2| languishing(row2) } ) },
        'Distinct Genotype Confirmed ES Cells' => lambda { |group| distinct_genotype_confirmed_es_cells(group) },
        'Distinct Old Non Genotype Confirmed ES Cells' => lambda { |group| distinct_old_non_genotype_confirmed_es_cells(group) }

        ).each do |row|

          pc = efficiency(request, row)
          pc2 = efficiency2(request, row)

          report_table << {
            'Consortium' => consortium,
            'Production Centre' => row['Production Centre'],
            'All' => row['All'],
            'ES QC started' => row['ES QC started'],
            'ES QC confirmed' => row['ES QC confirmed'],
            'ES QC failed' => row['ES QC failed'],
            'MI in progress' => row['MI in progress'],
            'Genotype Confirmed Mice' => row['Genotype Confirmed Mice'],
            'MI Aborted' => row['MI Aborted'],
            'Languishing' => row['Languishing'],
            'Registered for Phenotyping' => row['Registered for Phenotyping'],
            'Distinct Genotype Confirmed ES Cells' => row['Distinct Genotype Confirmed ES Cells'],
            'Distinct Old Non Genotype Confirmed ES Cells' => row['Distinct Old Non Genotype Confirmed ES Cells'],
            'Pipeline efficiency (%)' => pc,
            'Pipeline efficiency (by clone)' => pc2
          }
        
        end
    end

    return REPORT_TITLE, report_table
  end

end
