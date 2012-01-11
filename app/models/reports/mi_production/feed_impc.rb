# encoding: utf-8

class Reports::MiProduction::FeedImpc

  extend Reports::Helper
  extend ActionView::Helpers::UrlHelper
  extend Reports::MiProduction::Helper
  
  DEBUG = false      
  CSV_LINKS = true  

  MAPPING = {
    'All Projects' => [
      'Inactive',
      'Withdrawn'
    ],
    'Project started' => ['Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete', 'Micro-injection in progress', 'Genotype confirmed'],
    'Microinjection in progress' => ['Micro-injection in progress', 'Genotype confirmed'],
    'Genotype Confirmed Mice' => ['Genotype confirmed'],
    'Phenotyping in progress' => ['Phenotyping Started'],
    'Phenotype data available' => ['Phenotyping Complete']
  }

  def self.subsummary(request, params)
    consortium = params[:consortium]
    status = params[:type]

    script_name = request ? request.url : ''
    script_name = script_name.gsub(/production_summary1\?.+/, '')
    
    report_table = Table([  'Consortium', 'Production Centre', 'Status', 'Marker symbol', 'Details at IKMC', 'Order', 'Mutation type',
        'Allele name', 'Genetic background' ] )

    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table
  
    Table(:data => cached_report.data,
      :column_names => cached_report.column_names,
      :filters => lambda {|r|
        
        consortium_ok = consortium && consortium.length > 0
        
        return (!consortium_ok || r['Consortium'] == consortium) && (! MAPPING['All Projects'].include?(r.data['MiPlan Status'])) if status == 'All Projects'
        
        return (!consortium_ok || r['Consortium'] == consortium) &&
          (MAPPING[status].include?(r.data['Overall Status']) || MAPPING[status].include?(r.data['PhenotypeAttempt Status']))
      }
    ).each do |row|

      make_link = lambda {|value|
        status = row['Overall Status']
        project_id = row['IKMC Project ID']
        accession_id = row['MGI Accession ID']
        gene = row['Gene']
        
        return '' if (!project_id || project_id.length < 1) && (!accession_id || accession_id.length < 1) && (!gene || gene.length < 1)
        
        href1 = "http://www.knockoutmouse.org/martsearch/search?query=#{gene}"
        href2 = "http://www.knockoutmouse.org/martsearch/search?query=#{accession_id}"
        href3 = "http://www.knockoutmouse.org/martsearch/project/#{project_id}"
            
        return project_id if request && request.format == :csv && status == 'Genotype confirmed'
        return accession_id if request && request.format == :csv && accession_id
        return gene if request && request.format == :csv
        
        return "<a target='_blank' title='Click through to IKMC (PID:#{project_id})' href='#{href3}'>Details</a>" if status == 'Genotype confirmed' && project_id && project_id.length > 0
        return "<a target='_blank' title='Click through to IKMC (AID:#{accession_id})' href='#{href2}'>Details</a>" if accession_id && accession_id.length > 0
        return "<a target='_blank' title='Click through to IKMC (Gene:#{gene})' href='#{href1}'>Details</a>" if gene && gene.length > 0 && gene != '(no gene)'
        return ''
      }
      
      # use the script name to get path to icon

      img = script_name.gsub(/\/reports\/.+$/, "/images/ikmc-favicon.ico")

      make_link2 = lambda {|row|
        return row['IKMC Project ID'].to_s.length > 1 ? row['IKMC Project ID'] : '' if request && request.format == :csv
        return '' if row['Overall Status'] != 'Genotype confirmed'
        row['IKMC Project ID'].to_s.length > 1 ?
          "<p style='margin: 0px; padding: 0px;text-align: center;'>" +
          "<a target='_blank' title='Click through to IKMC (#{row['IKMC Project ID']})' href='http://www.knockoutmouse.org/martsearch/project/#{row['IKMC Project ID']}'>" +
          "<img alt='Mouse Image' src='#{img}'></img></a></p>" :
          ''
      }
      
      mt = fix_mutation_type row['Mutation Sub-Type']

      report_table << {        
        'Consortium' => row['Consortium'],
        'Production Centre' => row['Production Centre'],
        'Marker symbol' => row['Gene'],
        'Details at IKMC' => make_link.call(row['IKMC Project ID']),
        'Order' => make_link2.call(row),
        'Mutation type' => mt,
        'Allele name' => row['Allele Symbol'],
        'Genetic background' => row['Genetic Background'],
        'Status' => row['Overall Status']
      }
    end

    title = "Production Summary 1 Detail (feed)"
    title = "Production Summary 1 Detail: Consortium: #{consortium} - Type: #{status} (#{report_table.size})" if DEBUG
    
    return title, report_table
  end

  
  def self.generate(request = nil, params = {})

    if params[:consortium]
      return subsummary(request, params)
    end
    
    script_name = request ? request.url : ''
          
    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table
    
    headings_main = [ 'Consortium', 'All Projects', 'Project started', 'Microinjection in progress', 'Genotype Confirmed Mice',
      'Phenotype data available']
    
    headings_supplemental = [
      'Project started_distinct', 'Microinjection in progress_distinct', 'Genotype Confirmed Mice_distinct',
      'All Projects_distinct', 'Phenotype data available_distinct'
    ]
    
    report_table = Table( headings_main + headings_supplemental )
   
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Priority' ] )
        
    grouped_report.summary(
      'Consortium',
      'All Projects'                => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| (! MAPPING['All Projects'].include?(row.data['MiPlan Status'])) } ) },
      'Project started'           => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING['Project started'].include? row.data['Overall Status'] } ) },
      'Microinjection in progress' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING['Microinjection in progress'].include? row.data['Overall Status'] } ) },
      'Genotype Confirmed Mice'           => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING['Genotype Confirmed Mice'].include? row.data['Overall Status'] } ) },
      'Phenotype data available'           => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING['Phenotype data available'].include? row.data['Overall Status'] } ) },

      'All Projects_distinct'                => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| (! MAPPING['All Projects'].include?(row.data['MiPlan Status'])) } ) },
      'Project started_distinct'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING['Project started'].include? row.data['Overall Status'] } ) },
      'Microinjection in progress_distinct' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING['Microinjection in progress'].include? row.data['Overall Status'] } ) },
      'Genotype Confirmed Mice_distinct'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING['Genotype Confirmed Mice'].include? row.data['Overall Status'] } ) },
      'Phenotyping in progress_distinct'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING['Phenotyping in progress'].include? row.data['PhenotypeAttempt Status'] } ) },
      'Phenotype data available_distinct'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING['Phenotype data available'].include? row.data['PhenotypeAttempt Status'] } ) }
    ).each do |row|

      make_link = lambda {|key|
        return row[key] if request && request.format == :csv
        consortium = CGI.escape row['Consortium']
        type = CGI.escape key
        separator = /\?/.match(script_name) ? '&' : '?'
        row[key].to_s != '0' ?
          "<a title='Click to see list of #{key}' href='#{script_name}#{separator}consortium=#{consortium}&type=#{type}'>#{row[key]}</a>" :
          ''
      }
      
      report_table << {        
        'Consortium' => row['Consortium'],
        'All Projects' => make_link.call('All Projects'),
        'Project started' => make_link.call('Project started'),
        'Microinjection in progress' => make_link.call('Microinjection in progress'),
        'Genotype Confirmed Mice' => make_link.call('Genotype Confirmed Mice'),
        'Phenotyping in progress' => make_link.call('Phenotyping in progress'),
        'Phenotype data available' => make_link.call('Phenotype data available'),
 
        'All Projects_distinct' => row['All Projects_distinct'],
        'Project started_distinct' => row['Project started_distinct'],
        'Microinjection in progress_distinct' => row['Microinjection in progress_distinct'],
        'Genotype Confirmed Mice_distinct' => row['Genotype Confirmed Mice_distinct'],
        'Phenotype data available_distinct' => make_link.call('Phenotype data available_distinct'),
      }

    end
 
    summaries = {}
    
    report_table.sum { |r|
      report_table.column_names.each do |name|
        next if name == 'Consortium'
        match = 0
        match = /\>(\d+)\</.match(r[name].to_s) if r[name]
        match ||= /(\d+)/.match(r[name].to_s) if r[name]
        value = match && match[1] ? Integer(match[1]) : 0
        summaries[name] ||= 0
        summaries[name] += Integer(value)
      end
      0
    }

    make_sum = lambda {|key, anchor|
      return summaries[key] if request && request.format == :csv
      return '' if summaries[key] == 0
      return strong(summaries[key]) if ! anchor
      type = CGI.escape key
      type = type.gsub(/_distinct/, '')
      separator = /\?/.match(script_name) ? '&' : '?'
      summaries[key].to_s != '0' ?
        "<a title='Click to see list of #{type}' href='#{script_name}#{separator}consortium=&type=#{type}'>" +
        strong(summaries[key]) + "</a>" :
        ''
    }
    
    total = 'Total'
    total = strong('Total') if request && request.format != :csv
        
    report_table << {        
      'Consortium' => total,
      'All Projects' => make_sum.call('All Projects_distinct', true),
      'Project started' => make_sum.call('Project started_distinct', false),
      'Microinjection in progress' => make_sum.call('Microinjection in progress_distinct', false),
      'Genotype Confirmed Mice' => make_sum.call('Genotype Confirmed Mice_distinct', false),
      'Phenotyping in progress' => make_sum.call('Phenotyping in progress_distinct', false),
      'Phenotype data available' => make_sum.call('Phenotype data available_distinct', false)
    }
  
    report_table.reorder(headings_main)
       
    return 'Production Summary 1 (feed)', report_table
  end
  
end
