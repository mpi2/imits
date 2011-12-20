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

  #Confirm that 'All projects' excludes MIPlan Inactive, MI Plan Withdrawn.
    
  CSV_LINKS = true  
  ADD_COUNTS = false
  LIMIT_CONSORTIA = false
  ADD_ALL_PRIORITIES = false
  CONSORTIA = [ 'BaSH', 'DTCC', 'Helmholtz GMC', 'JAX', 'MARC', 'MGP', 'Monterotondo', 'NorCOMM2', 'Phenomin', 'RIKEN BRC' ]
#  ORDER_BY_MAP = { 'Low' => 1, 'Medium' => 2, 'High' => 3}
  ORDER_BY_MAP = { 'Low' => 3, 'Medium' => 2, 'High' => 1}
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
    'Genotype Confirmed Mice' => ['Genotype confirmed'],
    'Aborted' => ['Micro-injection aborted'],
    'Phenotyping in progress' => ['Phenotyping Started Date'],
    'Phenotype data available' => ['Phenotyping Complete Date']
  }
  MAPPING3 = {
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
  
  #Columns:
  #Consortium
  #Production Centre
  #Marker symbol
  #"Order at IKMC" - contains a link to the IKMC Project page at
  #www.knockoutmouse.org/martsearch/project/XXXXX
  #- this is available at the targrep and could be cached.
  #Mutation type - this is available at the targrep and could be cached.
  #Allele name (name of the mouse line, as stored in iMits)
  #Genetic background - as stored in iMits

  def self.subsummary1(params)
    consortium = params[:consortium]
    status = params[:type]

    report_table = Table([ 'Consortium', 'Production Centre', 'Marker symbol', 'Order at IKMC', 'Mutation type', 'Allele name', 'Genetic background' ] )

    @@cached_report ||= get_cached_report('mi_production_intermediate')
    
    counter = 1
    report = Table(:data => @@cached_report.data,
      :column_names => ADD_COUNTS ? ['Count'] + @@cached_report.column_names : @@cached_report.column_names,
      :filters => lambda {|r|
        return (r['Consortium'] == consortium) &&
        (MAPPING1[status].include?(r.data['Overall Status']) || MAPPING1[status].include?(r.data['PhenotypeAttempt Status']))
      },
      :transforms => lambda {|r|
        return if ! ADD_COUNTS
        r['Count'] = counter
        counter += 1
      }
    ).each do |row|
      report_table << {        
      'Consortium' => row['Consortium'],
      'Production Centre' => row['Production Centre'],
      'Marker symbol' => 'Unknown',
      'Order at IKMC' => 'Unknown',
      'Mutation type' => 'Unknown',
      'Allele name' => 'Unknown',
      'Genetic background' => 'Unknown'
      }
    end

    title = "Production Summary 1 Detail: Consortium: #{consortium} - Type: #{status} (#{report_table.size})"
    
    return title, report_table
  end

  #def self.subsummary1_old(params)
  #  consortium = params[:consortium] && params[:consortium].length > 0 ? params[:consortium] : nil
  #  status = params[:type]
  #
  #  @@cached_report ||= get_cached_report('mi_production_intermediate')
  #
  ##  genes = []
  #
  #  counter = 1
  #  report = Table(:data => @@cached_report.data,
  #    :column_names => ADD_COUNTS ? ['Count'] + @@cached_report.column_names : @@cached_report.column_names,
  #    #:filters => lambda {|r|
  #    #  if (!consortium || r['Consortium'] == consortium) &&
  #    #      MAPPING1[status].include?(r.data['Overall Status'])
  #    #    return false if genes.include?(r['Gene'])
  #    #    genes.push r['Gene']
  #    #    return true
  #    #  end
  #    #},
  #    :filters => lambda {|r|
  #      return (!consortium || r['Consortium'] == consortium) && MAPPING1[status].include?(r.data['Overall Status'])
  #    },
  #    :transforms => lambda {|r|
  #      return if ! ADD_COUNTS
  #      r['Count'] = counter
  #      counter += 1
  #    }
  #  )
  #
  #  title = "Production Summary 1 Detail: Consortium: #{consortium} - Type: #{status} (#{report.size})"
  #  
  #  return title, report
  #
  #end

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

  #Columns titles:
  #
  #All Projects
  #Project Started
  #Microinjection in progress
  #Mice available
  #Phenotyping in progress
  #Phenotyping data available
  #
  #Grand-total Counts must present unique genes, not simple totals of all the rows.
  #
  #Confirm that 'All projects' excludes MIPlan Inactive, MI Plan Withdrawn.
  
  def self.generate1(request = nil, params = {})

    if params[:consortium]
      return subsummary1(params)
    end
    
    script_name = request ? request.env['REQUEST_URI'] : ''
      
    @@cached_report ||= get_cached_report('mi_production_intermediate')

    report_table = Table( [ 'Consortium', 'All', 'Activity', 'Mice in production', 'Genotype Confirmed Mice', 'All_distinct',
        'Activity_distinct', 'Mice in production_distinct', 'GLT Mice_distinct', 'Phenotyping in progress', 'Phenotype data available' ] )
   
    grouped_report = Grouping( @@cached_report, :by => [ 'Consortium', 'Priority' ] )
        
    grouped_report.summary(
      'Consortium',
      'All'                => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['All'].include? row.data['Overall Status'] } ) },
      'Activity'           => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Activity'].include? row.data['Overall Status'] } ) },
      'Mice in production' => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Mice in production'].include? row.data['Overall Status'] } ) },
      'Genotype Confirmed Mice'           => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Genotype Confirmed Mice'].include? row.data['Overall Status'] } ) },
      'Phenotyping in progress'           => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Phenotyping in progress'].include? row.data['PhenotypeAttempt Status'] } ) },
      'Phenotype data available'           => lambda { |group| count_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Phenotype data available'].include? row.data['PhenotypeAttempt Status'] } ) },

      'All_distinct'                => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['All'].include? row.data['Overall Status'] } ) },
      'Activity_distinct'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Activity'].include? row.data['Overall Status'] } ) },
      'Mice in production_distinct' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Mice in production'].include? row.data['Overall Status'] } ) },
      'GLT Mice_distinct'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Genotype Confirmed Mice'].include? row.data['Overall Status'] } ) },
      'Phenotyping in progress_distinct'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Phenotyping in progress'].include? row.data['PhenotypeAttempt Status'] } ) },
      'Phenotype data available_distinct'           => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING1['Phenotype data available'].include? row.data['PhenotypeAttempt Status'] } ) }
    ).each do |row|
            
      make_link = lambda {|key|
        return row[key] if request && request.format == :csv
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
        'Genotype Confirmed Mice' => make_link.call('Genotype Confirmed Mice'),
        'Phenotyping in progress' => make_link.call('Phenotyping in progress'),
        'Phenotype data available' => make_link.call('Phenotype data available'),
 
        'All_distinct' => row['All_distinct'],
        'Activity_distinct' => row['Activity_distinct'],
        'Mice in production_distinct' => row['Mice in production_distinct'],
        'GLT Mice_distinct' => row['GLT Mice_distinct'],
        'Phenotyping in progress_distinct' => make_link.call('Phenotyping in progress_distinct'),
        'Phenotype data available_distinct' => make_link.call('Phenotype data available_distinct'),
      }

    end

    summaries = { 'All' => 0, 'Activity' => 0, 'Mice in production' => 0, 'Genotype Confirmed Mice' => 0,
      'All_distinct' => 0, 'Activity_distinct' => 0, 'Mice in production_distinct' => 0, 'GLT Mice_distinct' => 0,
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

    make_sum = lambda {|value|
      return value if request && request.format == :csv
      return strong(value)
    }
        
    report_table << {        
      'Consortium' => make_sum.call('Total'),
      'All' => make_sum.call(summaries['All_distinct']),
      'Activity' => make_sum.call(summaries['Activity_distinct']),
      'Mice in production' => make_sum.call(summaries['Mice in production_distinct']),
      'Genotype Confirmed Mice' => make_sum.call(summaries['GLT Mice_distinct']),
      'Phenotyping in progress' => make_sum.call(summaries['Phenotyping in progress_distinct']),
      'Phenotype data available' => make_sum.call(summaries['Phenotype data available_distinct'])
    }
    
    report_table.rename_column("All","All Projects")
    report_table.rename_column("Activity","Project started")
    report_table.rename_column("Mice in production","Microinjection in progress")
    report_table.rename_column("GLT Mice","Mice available")

#    report_table.add_column("Phenotype data available", :after => 'Mice available')
#    report_table.add_column("Phenotyping in progress", :after => 'Mice available')

    report_table.remove_column("All_distinct")
    report_table.remove_column("Activity_distinct")
    report_table.remove_column("Mice in production_distinct")
    report_table.remove_column("GLT Mice_distinct")
       
    return 'Production Summary 1 (feed)', report_table
  end
 
  #Column labels and notes:
  #
  #1) All - this must include the inactive etc cases
  #
  #2) Separate columns for
  #ES QC started
  #ES QC confirmed
  #ES QC failed
  #
  #3) Aborted => MI Aborted.
  #
  #4) GLT Mice => Genotype Confirmed Mice
  #
  #5) Pipeline Efficiency now computed by:
  #Number of genotype confirmed mice right now /
  #(Number of active MI plans with non-aborted MIs more than 6 months old + number of genotype confirmed mice right now)

  def self.generate2(request = nil, params={})

    if params[:consortium]
      return subsummary_common(params)
    end

    script_name = request ? request.env['REQUEST_URI'] : ''
    script_name = script_name.gsub(/_all/, '2') # blag the url if we're called from _all

    @@cached_report ||= get_cached_report('mi_production_intermediate')

    report_table = Table( ['Consortium', 'All', 'ES QC started', 'ES QC confirmed', 'ES QC failed', 'MI in progress', 'MI Aborted', 'Genotype Confirmed Mice', 'Pipeline efficiency (%)'] )
 
    grouped_report = Grouping( @@cached_report, :by => [ 'Consortium' ] )
    
    summary = grouped_report.summary(
      'Consortium',
      'All'            => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING3['All'].include? row.data['Overall Status'] } ) },
      'ES QC started'  => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING3['ES QC started'].include? row.data['Overall Status'] } ) },
      'MI in progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING3['MI in progress'].include? row.data['Overall Status'] } ) },
      'Genotype Confirmed Mice'       => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING3['Genotype Confirmed Mice'].include? row.data['Overall Status'] } ) },
      'MI Aborted'       => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING3['Aborted'].include? row.data['Overall Status'] } ) },
      'ES QC confirmed'       => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING3['ES QC confirmed'].include? row.data['Overall Status'] } ) },
      'ES QC failed'       => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| MAPPING3['ES QC failed'].include? row.data['Overall Status'] } ) }      
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

      glt = Integer(row['Genotype Confirmed Mice'])
      total = Integer(row['Genotype Confirmed Mice']) + Integer(row['MI Aborted'])
      pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
      pc = pc != 0 ? "%i" % pc : request && request.format != :csv ? '' : 0

      report_table << {
        'Consortium' => row['Consortium'],
        'Priority' => row['Priority'],
        'All' => make_link.call('All'),
        'ES QC started' => make_link.call('ES QC started'),
        'MI in progress' => make_link.call('MI in progress'),
        'Genotype Confirmed Mice' => make_link.call('Genotype Confirmed Mice'),
        'MI Aborted' => make_link.call('Aborted'),
        'Pipeline efficiency (%)' => pc,
        'ES QC confirmed' => make_link.call('ES QC confirmed'),
        'ES QC failed' => make_link.call('ES QC failed')
      }
      
    end
  
    report_table.sort_rows_by!( ['Consortium'] )    
        
    return 'Production Summary 2', report_table
  end

  #Column labels and notes:
  #
  #1) All - this must include the inactive etc cases
  #
  #2) Separate columns for
  #ES QC started
  #ES QC confirmed
  #ES QC failed
  #
  #3) Aborted => MI Aborted.
  #
  #4) GLT Mice => Genotype Confirmed Mice
  #
  #5) Pipeline Efficiency now computed by:
  #Number of genotype confirmed mice right now /
  #(Number of active MI plans with non-aborted MIs more than 6 months old + number of genotype confirmed mice right now)

  def self.generate3(request = nil, params={})

    if params[:consortium]
      return subsummary_common(params)
    end

    script_name = request ? request.env['REQUEST_URI'] : ''
    script_name = script_name.gsub(/_all/, '3') # blag the url if we're called from _all

    @@cached_report ||= get_cached_report('mi_production_intermediate')

    report_table = Table( ['Consortium', 'Priority', 'All', 'ES QC started', 'ES QC failed', 'ES QC confirmed', 'MI in progress', 'MI Aborted', 'Genotype Confirmed Mice', 'Pipeline efficiency (%)', 'order_by'] )
 
    grouped_report = Grouping( @@cached_report, :by => [ 'Consortium', 'Priority' ] )
    
    grouped_report.each do |consortium|
      
      next if LIMIT_CONSORTIA && ! CONSORTIA.include?(consortium)
      
      summary = grouped_report.subgrouping(consortium).summary(
        'Priority',
        'All'            => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING3['All'].include? row.data['Overall Status'] } ) },
        'ES QC started'  => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING3['ES QC started'].include? row.data['Overall Status'] } ) },
        'ES QC confirmed' => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING3['ES QC confirmed'].include? row.data['Overall Status'] } ) },
        'MI in progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING3['MI in progress'].include? row.data['Overall Status'] } ) },
        'Genotype Confirmed Mice'       => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING3['Genotype Confirmed Mice'].include? row.data['Overall Status'] } ) },
        'MI Aborted'       => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING3['MI Aborted'].include? row.data['Overall Status'] } ) },
        'ES QC failed'       => lambda { |group| count_unique_instances_of( group, 'Gene',
            lambda { |row| MAPPING3['ES QC failed'].include? row.data['Overall Status'] } ) }
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

        glt = Integer(row['Genotype Confirmed Mice'])
        total = Integer(row['Genotype Confirmed Mice']) + Integer(row['MI Aborted'])
        pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
        pc = pc != 0 ? "%i" % pc : request && request.format != :csv ? '' : 0

        p_found.push row['Priority']
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
          'ES QC failed' => make_link.call('ES QC failed')
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

    @@cached_report ||= get_cached_report('mi_production_intermediate')

    report_table = Table( ['Consortium', 'Sub-Project', 'Priority', 'All', 'ES QC started', 'ES QC confirmed', 'MI in progress', 'Aborted', 'Genotype Confirmed Mice', 'Pipeline efficiency (%)', 'order_by'] )
 
    grouped_report = Grouping( @@cached_report, :by => [ 'Consortium', 'Sub-Project', 'Priority' ] )
    
    grouped_report.each do |consortium|
      
#      next if LIMIT_CONSORTIA && ! CONSORTIA.include?(consortium)

      next if consortium != 'MGP'
      
      subgrouping = grouped_report.subgrouping(consortium)
      
      subgrouping.each do |subproject|      
      
        summary = subgrouping.subgrouping(subproject).summary(
          'Priority',
          'All'            => lambda { |group| count_unique_instances_of( group, 'Gene',
              lambda { |row| MAPPING3['All'].include? row.data['Overall Status'] } ) },
          'ES QC started'  => lambda { |group| count_unique_instances_of( group, 'Gene',
              lambda { |row| MAPPING3['ES QC started'].include? row.data['Overall Status'] } ) },
          'ES QC confirmed' => lambda { |group| count_unique_instances_of( group, 'Gene',
              lambda { |row| MAPPING3['ES QC confirmed'].include? row.data['Overall Status'] } ) },
          'MI in progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
              lambda { |row| MAPPING3['MI in progress'].include? row.data['Overall Status'] } ) },
          'Genotype Confirmed Mice'       => lambda { |group| count_unique_instances_of( group, 'Gene',
              lambda { |row| MAPPING3['Genotype Confirmed Mice'].include? row.data['Overall Status'] } ) },
          'Aborted'       => lambda { |group| count_unique_instances_of( group, 'Gene',
              lambda { |row| MAPPING3['Aborted'].include? row.data['Overall Status'] } ) }
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

          glt = Integer(row['Genotype Confirmed Mice'])
          total = Integer(row['Genotype Confirmed Mice']) + Integer(row['Aborted'])
          pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
          pc = pc != 0 ? "%i" % pc : request && request.format != :csv ? '' : 0

          p_found.push row['Priority']
          report_table << {
            'Consortium' => consortium,
            'Sub-Project' => subproject,
            'Priority' => row['Priority'],
            'All' => make_link.call('All'),
            'ES QC started' => make_link.call('ES QC started'),
            'ES QC confirmed' => make_link.call('ES QC confirmed'),
            'MI in progress' => make_link.call('MI in progress'),
            'Genotype Confirmed Mice' => make_link.call('Genotype Confirmed Mice'),
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
  
  # do this as a class
  
  def self.strong(param)
    #    return CGI.unescape param
    return '<strong>' + param.to_s + '</strong>'
  end  

  def self.subsummary_common(params)
    consortium = params[:consortium]
    type = params[:type]
    type = type ? type.gsub(/^\#\s+/, "") : nil
    priority = unescape params[:priority]
    subproject = unescape params[:subproject]    
  
    @@cached_report ||= get_cached_report('mi_production_intermediate')
  
    genes = []
    counter = 1
    report = Table(:data => @@cached_report.data,
      :column_names => ADD_COUNTS ? ['Count'] + @@cached_report.column_names : @@cached_report.column_names,
      :filters => lambda {|r|
        if r['Consortium'] == consortium &&
            (priority.nil? || r['Priority'] == priority) &&
            (type.nil? || MAPPING3[type].include?(r.data['Overall Status'])) &&
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
  
end
