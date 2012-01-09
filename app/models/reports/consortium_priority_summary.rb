# encoding: utf-8

class Reports::ConsortiumPrioritySummary

  extend Reports::Helper
  extend ActionView::Helpers::UrlHelper
  
  DEBUG = false
      
  CSV_LINKS = true  
  ORDER_BY_MAP = { 'Low' => 3, 'Medium' => 2, 'High' => 1}
  MAPPING_FEED = {
    'All' => [
      'Inactive',
      'Withdrawn'
    ],
    'Activity' => ['Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete', 'Micro-injection in progress', 'Genotype confirmed'],
    'Mice in production' => ['Micro-injection in progress', 'Genotype confirmed'],
    'Genotype Confirmed Mice' => ['Genotype confirmed'],
    'Phenotyping in progress' => ['Phenotyping Started Date'],
    'Phenotype data available' => ['Phenotyping Complete Date']
  }
  MAPPING_SUMMARIES = {
    'All' => [
      'Interest',
      'Assigned - ES Cell QC In Progress',
      'Assigned - ES Cell QC Complete',
      'Micro-injection in progress',
      'Assigned',
      'Inspect - MI Attempt',
      'Aborted - ES Cell QC Failed',
      'Conflict',
      'Genotype confirmed',
      'Inspect - Conflict',
      'Inspect - GLT Mouse',
      'Withdrawn',
      'Micro-injection aborted'
    ],
    'ES QC started' => ['Assigned - ES Cell QC In Progress'],
    'MI in progress' => ['Micro-injection in progress'],
    'Genotype Confirmed Mice' => ['Genotype confirmed'],
    'MI Aborted' => ['Micro-injection aborted'],
    'ES QC confirmed' => ['Assigned - ES Cell QC Complete'],
    'ES QC failed' => ['Aborted - ES Cell QC Failed']
  }
  CONSORTIA_SUMMARY4 = ['EUCOMM-EUMODIC', 'BaSH', 'MGP']

  def self.subsummary1(request, params)
    consortium = params[:consortium]
    status = params[:type]

    script_name = request ? request.url : ''
    script_name = script_name.gsub(/production_summary1\?.+/, '')
    
    report_table = Table([ 'Consortium', 'Production Centre', 'Status', 'Marker symbol', 'Details at IKMC', 'Order', 'Mutation type', 'Allele name', 'Genetic background' ] )

    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table
  
    Table(:data => cached_report.data,
      :column_names => cached_report.column_names,
      :filters => lambda {|r|
        
        consortium_ok = consortium && consortium.length > 0
        
        return (!consortium_ok || r['Consortium'] == consortium) && (! MAPPING_FEED['All'].include?(r.data['MiPlan Status'])) if status == 'All'
        
        return (!consortium_ok || r['Consortium'] == consortium) &&
          (MAPPING_FEED[status].include?(r.data['Overall Status']) || MAPPING_FEED[status].include?(r.data['PhenotypeAttempt Status']))
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
          "<img src='#{img}'></img></a></p>" :
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

  def self.count_instances_of( group, data_name, row_condition=nil )
    array = []
    group.each do |row|
      if row_condition.nil?
        array.push( row.data[data_name] )
      else
        array.push( row.data[data_name] ) if row_condition.call(row)
      end
    end
    array.size
  end
  
  def self.generate1(request = nil, params = {})

    if params[:consortium]
      return subsummary1(request, params)
    end
    
    script_name = request ? request.url : ''
          
    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table

    report_table = Table( [ 'Consortium', 'All', 'Activity', 'Mice in production', 'Genotype Confirmed Mice', 'All_distinct',
        'Activity_distinct', 'Mice in production_distinct', 'Genotype Confirmed Mice_distinct', 'Phenotype data available' ] )
   
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Priority' ] )
        
    grouped_report.summary(
      'Consortium',
      'All'                => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| (! MAPPING_FEED['All'].include?(row.data['MiPlan Status'])) } ) },
      'Activity'           => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_FEED['Activity'].include? row.data['Overall Status'] } ) },
      'Mice in production' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_FEED['Mice in production'].include? row.data['Overall Status'] } ) },
      'Genotype Confirmed Mice'           => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_FEED['Genotype Confirmed Mice'].include? row.data['Overall Status'] } ) },
      'Phenotyping in progress'           => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_FEED['Phenotyping in progress'].include? row.data['PhenotypeAttempt Status'] } ) },
      'Phenotype data available'           => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_FEED['Phenotype data available'].include? row.data['PhenotypeAttempt Status'] } ) },

      'All_distinct'                => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| (! MAPPING_FEED['All'].include?(row.data['MiPlan Status'])) } ) },
      'Activity_distinct'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING_FEED['Activity'].include? row.data['Overall Status'] } ) },
      'Mice in production_distinct' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING_FEED['Mice in production'].include? row.data['Overall Status'] } ) },
      'Genotype Confirmed Mice_distinct'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING_FEED['Genotype Confirmed Mice'].include? row.data['Overall Status'] } ) },
      'Phenotyping in progress_distinct'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING_FEED['Phenotyping in progress'].include? row.data['PhenotypeAttempt Status'] } ) },
      'Phenotype data available_distinct'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING_FEED['Phenotype data available'].include? row.data['PhenotypeAttempt Status'] } ) }
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
        'All' => make_link.call('All'),
        'Activity' => make_link.call('Activity'),
        'Mice in production' => make_link.call('Mice in production'),
        'Genotype Confirmed Mice' => make_link.call('Genotype Confirmed Mice'),
        'Phenotyping in progress' => make_link.call('Phenotyping in progress'),
        'Phenotype data available' => make_link.call('Phenotype data available'),
 
        'All_distinct' => row['All_distinct'],
        'Activity_distinct' => row['Activity_distinct'],
        'Mice in production_distinct' => row['Mice in production_distinct'],
        'Genotype Confirmed Mice_distinct' => row['Genotype Confirmed Mice_distinct'],
        'Phenotyping in progress_distinct' => make_link.call('Phenotyping in progress_distinct'),
        'Phenotype data available_distinct' => make_link.call('Phenotype data available_distinct'),
      }

    end
    
    #TODO: lose summaries initialization

    summaries = { 'All' => 0, 'Activity' => 0, 'Mice in production' => 0, 'Genotype Confirmed Mice' => 0,
      'All_distinct' => 0, 'Activity_distinct' => 0, 'Mice in production_distinct' => 0, 'Genotype Confirmed Mice_distinct' => 0,
      'Phenotyping in progress' => 0, 'Phenotype data available' => 0, 'Phenotyping in progress_distinct' => 0,
      'Phenotype data available_distinct' =>  0 }
    
    report_table.sum { |r|
      report_table.column_names.each do |name|
        next if name == 'Consortium'
        match = 0
        match = /\>(\d+)\</.match(r[name].to_s) if r[name]
        match ||= /(\d+)/.match(r[name].to_s) if r[name]
        value = match && match[1] ? Integer(match[1]) : 0
        summaries[name] += Integer(value)
      end
      0
    }

    make_sum = lambda {|key|
      return summaries[key] if request && request.format == :csv
      return '' if summaries[key] == 0
      type = CGI.escape key
      type = type.gsub(/_distinct/, '')
      separator = /\?/.match(script_name) ? '&' : '?'
      summaries[key].to_s != '0' ?
        "<a title='Click to see list of #{type}' href='#{script_name}#{separator}consortium=&type=#{type}'>" +
        strong(summaries[key]) + "</a>" :
        ''
    }
        
    report_table << {        
      'Consortium' => strong('Total'),
      'All' => make_sum.call('All_distinct'),
      'Activity' => strong(summaries['Activity_distinct']),
      'Mice in production' => strong(summaries['Mice in production_distinct']),
      'Genotype Confirmed Mice' => strong(summaries['Genotype Confirmed Mice_distinct']),
      'Phenotyping in progress' => !summaries['Phenotyping in progress_distinct'] || summaries['Phenotyping in progress_distinct'] == 0 ? '' : strong(summaries['Phenotyping in progress_distinct']),
      'Phenotype data available' => !summaries['Phenotype data available_distinct'] || summaries['Phenotype data available_distinct'] == 0 ? '' : strong(summaries['Phenotype data available_distinct'])
    }
    
    report_table.rename_column("All","All Projects")
    report_table.rename_column("Activity","Project started")
    report_table.rename_column("Mice in production","Microinjection in progress")
    report_table.rename_column("GLT Mice","Mice available")
    report_table.remove_column("All_distinct")
    report_table.remove_column("Activity_distinct")
    report_table.remove_column("Mice in production_distinct")
    report_table.remove_column("Genotype Confirmed Mice_distinct")
       
    return 'Production Summary 1 (feed)', report_table
  end

  def self.generate2(request = nil, params={})

    if params[:consortium]
      return subsummary_common(request, params)
    end

    script_name = request ? request.env['REQUEST_URI'] : ''
    script_name = script_name.gsub(/_all/, '2') # blag the url if we're called from _all

    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table

    report_table = Table( ['Consortium', 'All', 'ES QC started', 'ES QC confirmed', 'ES QC failed',
        'MI in progress', 'MI Aborted', 'Genotype Confirmed Mice', 'Pipeline efficiency (%)', 'Languishing'] )
 
    grouped_report = Grouping( cached_report, :by => [ 'Consortium' ] )
    
    summary = grouped_report.summary(
      'Consortium',
      'All'             => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING_SUMMARIES['All'].include? row.data['Overall Status'] } ) },
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
          lambda { |row| languishing(row) } ) }      
    )

    summary.each do |row|
        
      make_link = lambda {|key|
        return row[key] if request && request.format == :csv
        consort = CGI.escape row['Consortium']
        type = CGI.escape key
        id = (consort + '_' + type + '_').gsub(/\-|\+|\s+/, "_").downcase
        row[key].to_s != '0' ?
          "<a title='Click to see list of #{key}' id='#{id}' href='#{script_name}?consortium=#{consort}&type=#{type}'>#{row[key]}</a>" :
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
    
    report_table.remove_column 'Languishing' if ! DEBUG
  
    report_table.sort_rows_by!( ['Consortium'] )    
        
    return 'Production Summary 2', report_table
  end

  def self.generate3(request = nil, params={})

    if params[:consortium]
      return subsummary_common(request, params)
    end

    script_name = request ? request.env['REQUEST_URI'] : ''
    script_name = script_name.gsub(/_all/, '3') # blag the url if we're called from _all

    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table

    report_table = Table( ['Consortium', 'Priority', 'All', 'ES QC started', 'ES QC failed', 'ES QC confirmed', 'MI in progress', 'MI Aborted', 'Genotype Confirmed Mice', 'Pipeline efficiency (%)', 'order_by', 'Languishing'] )
 
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Priority' ] )
    
    grouped_report.each do |consortium|
        
      summary = grouped_report.subgrouping(consortium).summary(
        'Priority',
        'All'            => lambda { |group| count_instances_of( group, 'Gene',
            lambda { |row| MAPPING_SUMMARIES['All'].include? row.data['Overall Status'] } ) },
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
            lambda { |row| languishing(row) } ) }
      )
      
      summary.each do |row|
        
        make_link = lambda {|key|
          return row[key] if request && request.format == :csv
          consort = CGI.escape consortium
          type = CGI.escape key
          priority = CGI.escape row['Priority']
          id = (consort + '_' + type + '_' + priority).gsub(/\-|\+|\s+/, "_").downcase
          row[key].to_s != '0' ?
            "<a title='Click to see list of #{key}' id='#{id}' href='#{script_name}?consortium=#{consort}&type=#{key}&priority=#{priority}'>#{row[key]}</a>" :
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

    report_table.remove_column 'Languishing' if ! DEBUG
  
    report_table.sort_rows_by!( ['Consortium', 'order_by'] )    
    report_table.remove_column('order_by')
        
    return 'Production Summary 3', report_table
  end
  
  def self.generate4(request = nil, params={})

    if params[:consortium]
      return subsummary_common(request, params)
    end

    script_name = request ? request.env['REQUEST_URI'] : ''
    script_name = script_name.gsub(/_all/, '4') # blag the url if we're called from _all

    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table

    report_table = Table( ['Consortium', 'Sub-Project', 'Priority', 'All', 'ES QC started', 'ES QC failed', 'ES QC confirmed',
        'MI in progress', 'MI Aborted', 'Genotype Confirmed Mice', 'Pipeline efficiency (%)', 'order_by', 'Languishing'] )
 
    grouped_report = Grouping( cached_report, :by => [ 'Consortium', 'Sub-Project', 'Priority' ] )
   
    grouped_report.each do |consortium|
      
      next if ! CONSORTIA_SUMMARY4.include?(consortium)
      
      subgrouping = grouped_report.subgrouping(consortium)
      
      subgrouping.each do |subproject|      
      
        summary = subgrouping.subgrouping(subproject).summary(
          'Priority',
          'All'            => lambda { |group| count_instances_of( group, 'Gene',
              lambda { |row| MAPPING_SUMMARIES['All'].include? row.data['Overall Status'] } ) },
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
          'ES QC failed'   => lambda { |group| count_instances_of( group, 'Gene',
              lambda { |row| MAPPING_SUMMARIES['ES QC failed'].include? row.data['Overall Status'] } ) },
          'Languishing'        => lambda { |group| count_instances_of( group, 'Gene',
              lambda { |row| languishing(row) } ) }
        )
      
        summary.each do |row|
        
          make_link = lambda {|key|
            return row[key] if request && request.format == :csv
            consort = CGI.escape consortium
            type = CGI.escape key
            priority = CGI.escape row['Priority']
            sp = CGI.escape subproject
            id = (consort + '_' + type + '_' + priority).gsub(/\-|\+|\s+/, "_").downcase
            row[key].to_s != '0' ?
              "<a title='Click to see list of #{key}' id='#{id}' href='#{script_name}?consortium=#{consort}&type=#{key}&priority=#{priority}&subproject=#{sp}'>#{row[key]}</a>" :
              ''
          }

          pc = efficiency(request, row)

          report_table << {
            'Consortium' => consortium,
            'Sub-Project' => subproject,
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
  
    end

    report_table.remove_column 'Languishing' if ! DEBUG
  
    report_table.sort_rows_by!( ['Consortium', 'Sub-Project', 'order_by'] )    
    report_table.remove_column('order_by')
        
    return 'Production Summary 4', report_table
  end
  
  # TODO: do this as a class and not directly
  
  def self.strong(param)
    return '<strong>' + param.to_s + '</strong>'
  end
  
  def self.fix_mutation_type(mt)
    return "Knockout First" if mt == 'conditional_ready'
    mt = mt ? mt.gsub(/_/, ' ') : ''
    mt = mt.gsub(/\b\w/){$&.upcase}
    return mt
  end

  def self.subsummary_common(request, params)
    consortium = params[:consortium]
    type = params[:type]
    type = type ? type.gsub(/^\#\s+/, "") : nil
    priority = params[:priority]
    subproject = params[:subproject]    
  
    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table
      
    counter = 1
    report = Table(:data => cached_report.data,
      :column_names => cached_report.column_names,
      :filters => lambda {|r|
        if type != 'Languishing'
          return r['Consortium'] == consortium &&
            (priority.nil? || r['Priority'] == priority) &&
            (type.nil? || MAPPING_SUMMARIES[type].include?(r.data['Overall Status'])) &&
            (subproject.nil? || r['Sub-Project'] == subproject)
        else
          return r['Consortium'] == consortium &&
            (priority.nil? || r['Priority'] == priority) &&
            (subproject.nil? || r['Sub-Project'] == subproject) &&
            languishing(r)
        end
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
    
    consortium = consortium ? "Consortium: #{consortium} - " : ''
    subproject = subproject ? "Sub-Project: #{subproject} - " : ''
    type = type ? "Type: #{type} - " : ''
    priority = priority ? "Priority: #{priority} - " : ''
    
    report.rename_column 'Overall Status', 'Status'
    report.rename_column 'Mutation Sub-Type', 'Mutation Type'
  
    title = "Production Summary Detail"
    title = "Production Summary Detail: #{consortium}#{subproject}#{type}#{priority} (#{report.size})" if DEBUG
    
    return title, report
  end
   
  def self.efficiency(request, row)
    glt = Integer(row['Genotype Confirmed Mice'])
    failures = Integer(row['Languishing']) + Integer(row['MI Aborted'])
    total = Integer(row['Genotype Confirmed Mice']) + failures
    pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
    pc = pc != 0 ? "%i" % pc : request && request.format != :csv ? '' : 0
    return pc
  end

  def self.languishing(row)
    label = 'Micro-injection in progress'
    date = 'Micro-injection in progress Date'
    return false if row.data['Overall Status'] != label
    today = Date.today
    return false if ! row[date] || row[date].length < 1
    before = Date.parse(row[date])
    return false if ! before
    gap = today - before
    return gap && gap > 180
  end
    
end
