# encoding: utf-8

class Reports::FeedSummary

  extend Reports::Helper

  LOSE_ABORTS = false
  LOSE_SUB_DETAILS = false
  USE_COUNTER = true
 
  def self.subfeed(params)
    specs = params[:specs]
    array = specs.split('/')
    raise "Invalid parameters (#{array.size})" if array.size != 4

    centre = CGI.unescape array[1]
    column = CGI.unescape array[3]
    column = column.gsub(/^\#\s+/, "")
    raise "Invalid parameters: '#{array[0]}'" if array[0] != 'centre' || array[2] != 'status'
    
    @title2 = "subfeeds: centre: '#{centre}' - column: '#{column}' (#{array.size})"

    @cached_report ||= get_cached_report

    grouped_report = Grouping( @cached_report, :by => [ 'Production Centre'] )

    grouped_report = grouped_report[centre]
    grouped_report = Grouping( grouped_report, :by => [ 'Status'] )
    @report = grouped_report[column]
    
    column_names = [
      'Assigned - ES Cell QC In Progress Date',
      'Assigned - ES Cell QC Complete Date',
      'Micro-injection in progress Date',
      'Genotype confirmed Date',
      'Micro-injection aborted Date'
    ]
    
    if LOSE_SUB_DETAILS
      column_names.each do |name|
        r1 = Regexp.new(column)
        next if r1.match(name)
        @report.remove_column(name)
      end
      
      @report.remove_column('Production Centre')
      @report.remove_column('Status')
      @report.remove_column('Assigned Date')
      @report.remove_column('Sub-Project')
      @report.remove_column('Consortium')
      @report.remove_column('Priority')
    end

    @report.sort_rows_by!(["Gene"])

    if USE_COUNTER
      @report.add_column('Counter', :before => 'Gene')
      counter = 1
      @report.each do |row|
        row['Counter'] = counter
        counter += 1
      end
    end
      
    genes = []
    @report = Table(
      :data => @report.data,
      :column_names => @report.column_names,
      :filters => lambda {|r|
        if genes.include?(r['Gene'].downcase)
          return false
        end
        genes.push(r['Gene'].downcase)
        return true
      }
    )
      
    return @title2, @report
    
  end

  def self.clean_table(table, filter=true)
    column_names = [
      '# Assigned - ES Cell QC In Progress',
      '# Assigned - ES Cell QC Complete',
      '# Micro-injection in progress',
      '# Genotype confirmed',
      '# Micro-injection aborted'
    ]
    
    report = Table(:data => table.data,
      :column_names => table.column_names,
      :transforms => lambda {|r|
        column_names.each do |name|
          
          if r[name] == 0
            r[name] = ''
          else
            tname = CGI.escape(name)
            cname = CGI.escape(r['Production Centre'])
            r[name] ="<a href='/feeds/list/centre/#{cname}/status/#{tname}'>#{r[name]}</a>"
          end
          
        end
      },
      :filters => lambda {|r| ! filter || (r['Production Centre'] && r['Production Centre'].length > 0) }
    )
    report.remove_column('# Micro-injection aborted') if LOSE_ABORTS
    return report
  end

  def self.generate
    @cached_report ||= get_cached_report
      
    report_table = Table(
      [
        'Production Centre',
        '# Assigned - ES Cell QC In Progress',
        '# Assigned - ES Cell QC Complete',
        '# Micro-injection in progress',
        '# Genotype confirmed',
        '# Micro-injection aborted'
      ]
    )

    grouped_report = Grouping( @cached_report, :by => [ 'Production Centre' ], :order => [:name]  )

    grouped_report.summary(
      'Production Centre',
      '# Assigned - ES Cell QC In Progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| ((row.data['Status'] == 'Assigned - ES Cell QC In Progress')) ? true : false } ) },
      '# Assigned - ES Cell QC Complete' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| ((row.data['Status'] == 'Assigned - ES Cell QC Complete')) ? true : false } ) },
      '# Micro-injection in progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| ((row.data['Status'] == 'Micro-injection in progress')) ? true : false } ) },
      '# Genotype confirmed' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| ((row.data['Status'] == 'Genotype confirmed')) ? true : false } ) },
      '# Micro-injection aborted' => lambda { |group| count_unique_instances_of( group, 'Gene',
          lambda { |row| ((row.data['Status'] == 'Micro-injection aborted')) ? true : false } ) }
    ).each do |row|
      report_table << {
        'Production Centre' => row['Production Centre'],
        '# Assigned - ES Cell QC In Progress' => row['# Assigned - ES Cell QC In Progress'],
        '# Assigned - ES Cell QC Complete' => row['# Assigned - ES Cell QC Complete'],
        '# Micro-injection in progress' => row['# Micro-injection in progress'],
        '# Genotype confirmed' => row['# Genotype confirmed'],
        '# Micro-injection aborted' => row['# Micro-injection aborted']
      }
    end
   
    report_table.sort_rows_by!( '# Genotype confirmed', :order => :descending )

    report = clean_table(report_table)
    return report
  end

end
