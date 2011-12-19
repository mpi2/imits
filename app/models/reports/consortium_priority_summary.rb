# encoding: utf-8

class Reports::ConsortiumPrioritySummary

  extend Reports::Helper
  extend ActionView::Helpers::UrlHelper
  
  #Interest
  #Assigned - ES Cell QC In Progress
  #Assigned - ES Cell QC Complete
  #Micro-injection in progress
  #Assigned
  #Inspect - MI Attempt
  #Aborted - ES Cell QC Failed
  #Conflict
  #Genotype confirmed
  #Inspect - Conflict
  #Inspect - GLT Mouse
  #Withdrawn
  #Micro-injection aborted
    
  CSV_LINKS = true  
  ADD_COUNTS = false
  LIMIT_CONSORTIA = false
  ADD_ALL_PRIORITIES = false
  CONSORTIA = [ 'BaSH', 'DTCC', 'Helmholtz GMC', 'JAX', 'MARC', 'MGP', 'Monterotondo', 'NorCOMM2', 'Phenomin', 'RIKEN BRC' ]
  ORDER_BY_MAP = { 'Low' => 1, 'Medium' => 2, 'High' => 3}
  MAPPING1 = {
    'All' => ['Interest',
      'Assigned - ES Cell QC In Progress',
      'Assigned - ES Cell QC Complete',
      'Micro-injection in progress',
      'Assigned',
      'Inspect - MI Attempt',
      'Conflict',
      'Genotype confirmed',
      'Inspect - Conflict',
      'Inspect - GLT Mouse'],
    'Activity' => ['Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete', 'Micro-injection in progress', 'Genotype confirmed'],
    'Mice in production' => ['Micro-injection in progress', 'Genotype confirmed'],
    'GLT Mice' => ['Genotype confirmed'],
    'Aborted' => ['Micro-injection aborted']
  }
  MAPPING3 = {
    'All' => ['Interest',
      'Assigned - ES Cell QC In Progress',
      'Assigned - ES Cell QC Complete',
      'Micro-injection in progress',
      'Assigned',
      'Inspect - MI Attempt',
      'Conflict',
      'Genotype confirmed',
      'Inspect - Conflict',
      'Inspect - GLT Mouse'],
    'ES QC started' => ['Assigned - ES Cell QC In Progress'],
    'ES QC finished' => ['Assigned - ES Cell QC Complete'],
    'MI in progress' => ['Micro-injection in progress'],
    'GLT Mice' => ['Genotype confirmed'],
    'Aborted' => ['Micro-injection aborted']
  }

  def self.subsummary1(params)
    consortium = params[:consortium]
    status = params[:type]

    @@cached_report ||= get_cached_report('mi_production_detail')

    genes = []

    counter = 1
    report = Table(:data => @@cached_report.data,
      :column_names => ADD_COUNTS ? ['Count'] + @@cached_report.column_names : @@cached_report.column_names,
      :filters => lambda {|r|
        if r['Consortium'] == consortium && MAPPING1[status].include?(r.data['Status'])
          return false if genes.include?(r['Gene'])
          genes.push r['Gene']
          return true
        end
      },
      :transforms => lambda {|r|
        return if ! ADD_COUNTS
        r['Count'] = counter
        counter += 1
      }
    )

    title = "Production Summary 1 Detail: Consortium: #{consortium} - Type: #{status} (#{report.size})"
    
    return title, report

  end
  
  def self.generate1(request = nil, params = {})

    if params[:consortium]
      return subsummary1(params)
    end
    
    script_name = request ? request.env['REQUEST_URI'] : ''
  
    @@cached_report ||= get_cached_report('mi_production_detail')

    report_table = Table( [ 'Consortium', 'All', 'Activity', 'Mice in production', 'GLT Mice' ] )
   
    grouped_report = Grouping( @@cached_report, :by => [ 'Consortium', 'Priority' ] )
        
    grouped_report.summary(
      'Consortium',
      'All'                => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['All'].include? row.data['Status'] } ) },
      'Activity'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Activity'].include? row.data['Status'] } ) },
      'Mice in production' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Mice in production'].include? row.data['Status'] } ) },
      'GLT Mice'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['GLT Mice'].include? row.data['Status'] } ) },
      'Aborted'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Aborted'].include? row.data['Status'] } ) }
    ).each do |row|
            
      make_link = lambda {|key|
        consortium = escape row['Consortium']
        type = escape key
        row[key].to_s != '0' ?
          "<a title='Click to see list of #{key}' href='#{script_name}?consortium=#{consortium}&type=#{type}'>#{row[key]}</a>" :
          ''
      }

      report_table << {        
        'Consortium' => row['Consortium'],
        'All' => make_link.call('All'),
        'Activity' => make_link.call('Activity'),
        'Mice in production' => make_link.call('Mice in production'),
        'GLT Mice' => make_link.call('GLT Mice')
      }
    end
   
    report_table.sort_rows_by!( ['Consortium'] )
    
    return 'Production Summary 1 (feed)', report_table
  end
 
  def self.generate2(request = nil, params={})

    if params[:consortium]
      return subsummary_common(params)
    end

    script_name = request ? request.env['REQUEST_URI'] : ''
    script_name = script_name.gsub(/_all/, '2') # blag the url if we're called from _all

    @@cached_report ||= get_cached_report('mi_production_detail')

    report_table = Table( ['Consortium', 'All', 'ES QC started', 'ES QC finished', 'MI in progress', 'Aborted', 'GLT Mice', 'Pipeline efficiency (%)'] )
 
    grouped_report = Grouping( @@cached_report, :by => [ 'Consortium' ] )
    
    summary = grouped_report.summary(
      'Consortium',
      'All'            => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING3['All'].include? row.data['Status'] } ) },
      'ES QC started'  => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING3['ES QC started'].include? row.data['Status'] } ) },
      'ES QC finished' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING3['ES QC finished'].include? row.data['Status'] } ) },
      'MI in progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING3['MI in progress'].include? row.data['Status'] } ) },
      'GLT Mice'       => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING3['GLT Mice'].include? row.data['Status'] } ) },
      'Aborted'       => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING3['Aborted'].include? row.data['Status'] } ) }
    )

    summary.each do |row|
        
      make_link = lambda {|key|
        return row[key] if request && request.format == :csv
        consort = escape row['Consortium']
        type = escape key
        id = (consort + '_' + type + '_').gsub(/\-|\+|\s+/, "_").downcase
        row[key].to_s != '0' ?
          "<a title='Click to see list of #{key}' id='#{id}' href='#{script_name}?consortium=#{consort}&type=#{key}'>#{row[key]}</a>" :
          ''
      }

      glt = Integer(row['GLT Mice'])
      total = Integer(row['GLT Mice']) + Integer(row['Aborted'])
      pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
      pc = pc != 0 ? "%.2f" % pc : request && request.format != :csv ? '' : 0

      report_table << {
        'Consortium' => row['Consortium'],
        'Priority' => row['Priority'],
        'All' => make_link.call('All'),
        'ES QC started' => make_link.call('ES QC started'),
        'ES QC finished' => make_link.call('ES QC finished'),
        'MI in progress' => make_link.call('MI in progress'),
        'GLT Mice' => make_link.call('GLT Mice'),
        'Aborted' => make_link.call('Aborted'),
        'Pipeline efficiency (%)' => pc
      }
      
    end
  
    report_table.sort_rows_by!( ['Consortium'] )    
        
    return 'Production Summary 2', report_table
  end

  def self.generate3(request = nil, params={})

    if params[:consortium]
      return subsummary_common(params)
    end

    script_name = request ? request.env['REQUEST_URI'] : ''
    script_name = script_name.gsub(/_all/, '3') # blag the url if we're called from _all

    @@cached_report ||= get_cached_report('mi_production_detail')

    report_table = Table( ['Consortium', 'Priority', 'All', 'ES QC started', 'ES QC finished', 'MI in progress', 'Aborted', 'GLT Mice', 'Pipeline efficiency (%)', 'order_by'] )
 
    grouped_report = Grouping( @@cached_report, :by => [ 'Consortium', 'Priority' ] )
    
    grouped_report.each do |consortium|
      
      next if LIMIT_CONSORTIA && ! CONSORTIA.include?(consortium)
      
      summary = grouped_report.subgrouping(consortium).summary(
        'Priority',
        'All'            => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING3['All'].include? row.data['Status'] } ) },
        'ES QC started'  => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING3['ES QC started'].include? row.data['Status'] } ) },
        'ES QC finished' => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING3['ES QC finished'].include? row.data['Status'] } ) },
        'MI in progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING3['MI in progress'].include? row.data['Status'] } ) },
        'GLT Mice'       => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING3['GLT Mice'].include? row.data['Status'] } ) },
        'Aborted'       => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING3['Aborted'].include? row.data['Status'] } ) }
      )
      
      p_found = []

      summary.each do |row|
        
        make_link = lambda {|key|
          return row[key] if request && request.format == :csv
          consort = escape consortium
          type = escape key
          priority = escape row['Priority']
          id = (consort + '_' + type + '_' + priority).gsub(/\-|\+|\s+/, "_").downcase
          row[key].to_s != '0' ?
            "<a title='Click to see list of #{key}' id='#{id}' href='#{script_name}?consortium=#{consort}&type=#{key}&priority=#{priority}'>#{row[key]}</a>" :
            ''
        }

        glt = Integer(row['GLT Mice'])
        total = Integer(row['GLT Mice']) + Integer(row['Aborted'])
        pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
        pc = pc != 0 ? "%.2f" % pc : request && request.format != :csv ? '' : 0

        p_found.push row['Priority']
        report_table << {
          'Consortium' => consortium,
          'Priority' => row['Priority'],
          'All' => make_link.call('All'),
          'ES QC started' => make_link.call('ES QC started'),
          'ES QC finished' => make_link.call('ES QC finished'),
          'MI in progress' => make_link.call('MI in progress'),
          'GLT Mice' => make_link.call('GLT Mice'),
          'Aborted' => make_link.call('Aborted'),
          'Pipeline efficiency (%)' => pc,
          'order_by' => ORDER_BY_MAP[row['Priority']]
        }
      end
      
      next if ! ADD_ALL_PRIORITIES
      
      p_remain = [ 'Low', 'Medium', 'High' ] - p_found
      p_remain.each do |priority|
        report_table << {
          'Consortium' => consortium,
          'Priority' => priority,
          'order_by' => ORDER_BY_MAP[priority]
        }
      end
      
    end
  
    report_table.sort_rows_by!( ['Consortium', 'order_by'] )    
    report_table.remove_column('order_by')
        
    return 'Production Summary 3', report_table
  end

  def self.generate4(request = nil, params={})

    if params[:consortium]
      return subsummary_common(params)
    end

    script_name = request ? request.env['REQUEST_URI'] : ''
    script_name = script_name.gsub(/_all/, '4') # blag the url if we're called from _all

    @@cached_report ||= get_cached_report('mi_production_detail')

    report_table = Table( ['Consortium', 'Sub-Project', 'Priority', 'All', 'ES QC started', 'ES QC finished', 'MI in progress', 'Aborted', 'GLT Mice', 'Pipeline efficiency (%)', 'order_by'] )
 
    grouped_report = Grouping( @@cached_report, :by => [ 'Consortium', 'Sub-Project', 'Priority' ] )
    
    grouped_report.each do |consortium|
      
      next if LIMIT_CONSORTIA && ! CONSORTIA.include?(consortium)
      
      subgrouping = grouped_report.subgrouping(consortium)
      
      subgrouping.each do |subproject|      
      
        summary = subgrouping.subgrouping(subproject).summary(
          'Priority',
          'All'            => lambda { |group| count_unique_instances_of( group, 'Gene',
              lambda { |row| MAPPING3['All'].include? row.data['Status'] } ) },
          'ES QC started'  => lambda { |group| count_unique_instances_of( group, 'Gene',
              lambda { |row| MAPPING3['ES QC started'].include? row.data['Status'] } ) },
          'ES QC finished' => lambda { |group| count_unique_instances_of( group, 'Gene',
              lambda { |row| MAPPING3['ES QC finished'].include? row.data['Status'] } ) },
          'MI in progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
              lambda { |row| MAPPING3['MI in progress'].include? row.data['Status'] } ) },
          'GLT Mice'       => lambda { |group| count_unique_instances_of( group, 'Gene',
              lambda { |row| MAPPING3['GLT Mice'].include? row.data['Status'] } ) },
          'Aborted'       => lambda { |group| count_unique_instances_of( group, 'Gene',
              lambda { |row| MAPPING3['Aborted'].include? row.data['Status'] } ) }
        )
      
        p_found = []

        summary.each do |row|
        
          make_link = lambda {|key|
            return row[key] if request && request.format == :csv
            consort = escape consortium
            type = escape key
            priority = escape row['Priority']
            subproject = escape subproject
            id = (consort + '_' + type + '_' + priority).gsub(/\-|\+|\s+/, "_").downcase
            row[key].to_s != '0' ?
              "<a title='Click to see list of #{key}' id='#{id}' href='#{script_name}?consortium=#{consort}&type=#{key}&priority=#{priority}&subproject=#{subproject}'>#{row[key]}</a>" :
              ''
          }

          glt = Integer(row['GLT Mice'])
          total = Integer(row['GLT Mice']) + Integer(row['Aborted'])
          pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
          pc = pc != 0 ? "%.2f" % pc : request && request.format != :csv ? '' : 0

          p_found.push row['Priority']
          report_table << {
            'Consortium' => consortium,
            'Sub-Project' => subproject,
            'Priority' => row['Priority'],
            'All' => make_link.call('All'),
            'ES QC started' => make_link.call('ES QC started'),
            'ES QC finished' => make_link.call('ES QC finished'),
            'MI in progress' => make_link.call('MI in progress'),
            'GLT Mice' => make_link.call('GLT Mice'),
            'Aborted' => make_link.call('Aborted'),
            'Pipeline efficiency (%)' => pc,
            'order_by' => ORDER_BY_MAP[row['Priority']]
          }
        end
      end
      
      next if ! ADD_ALL_PRIORITIES
      
      p_remain = [ 'Low', 'Medium', 'High' ] - p_found
      p_remain.each do |priority|
        report_table << {
          'Consortium' => consortium,
          'Priority' => priority,
          'order_by' => ORDER_BY_MAP[priority]
        }
      end
      
    end
  
    report_table.sort_rows_by!( ['Consortium', 'Sub-Project', 'order_by'] )    
    report_table.remove_column('order_by')
        
    return 'Production Summary 4', report_table
  end

  def self.escape(param)
    #    return CGI.escape param
    return param
  end
  def self.unescape(param)
    #    return CGI.unescape param
    return param
  end  

  def self.subsummary_common(params)
    consortium = params[:consortium]
    type = params[:type]
    type = type ? type.gsub(/^\#\s+/, "") : nil
    priority = unescape params[:priority]
    subproject = unescape params[:subproject]    
  
    @@cached_report ||= get_cached_report('mi_production_detail')
  
    genes = []
    counter = 1
    report = Table(:data => @@cached_report.data,
      :column_names => ADD_COUNTS ? ['Count'] + @@cached_report.column_names : @@cached_report.column_names,
      :filters => lambda {|r|
        if r['Consortium'] == consortium &&
            (priority.nil? || r['Priority'] == priority) &&
            (type.nil? || MAPPING3[type].include?(r.data['Status'])) &&
            (subproject.nil? || r['Sub-Project'] == subproject)
          return false if genes.include?(r['Gene'])
          genes.push r['Gene']
          return true
        end
      },
      :transforms => lambda {|r|
        return if ! ADD_COUNTS
        r['Count'] = counter
        counter += 1
      }
    )
    
    consortium = consortium ? "Consortium: #{consortium} - " : ''
    subproject = subproject ? "Sub-Project: #{subproject} - " : ''
    type = type ? "Type: #{type} - " : ''
    priority = priority ? "Priority: #{priority} - " : ''
  
    title = "Production Summary Detail: #{consortium}#{subproject}#{type}#{priority} (#{report.size})"
    
    return title, report
  end

  #def self.generate_all(request, params)
  #  @title2, @report2 = Reports::ConsortiumPrioritySummary.generate2(request, params)
  #  @title2, @report3 = Reports::ConsortiumPrioritySummary.generate3(request, params)
  #  @title2, @report4 = Reports::ConsortiumPrioritySummary.generate4(request, params)
  #  return [@report2, @report3, @report4]
  #end
  
end
