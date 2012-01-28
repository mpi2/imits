# encoding: utf-8

class Reports::MiProduction::SummaryMonthByMonthActivity
  
  LIMIT = 10
  VERBOSE = false

  def self.generate(request = nil, params={})
    table = params['table'].blank? ? 2 : params['table'].to_i
    tables = generate_original
#raise table.inspect
    return table > -1 && table < tables.size ? tables[table] : nil
  end

 #def self.generate(request = nil, params={})
 #   table = params['table'].blank? ? nil : params['table'].to_i
 #   #return generate_plans(request, params)
 #   #return generate_attempts(request, params)
 #   return generate_original
 #   # return nil
 #end
 
  def self.generate_attempts(request = nil, params={})
    
    headings = ['Year', 'Month', 'Consortium', 'Gene id', 'Status']
    table = Table(headings)
    
    MiAttempt::StatusStamp.all.each do |stamp|
      table << {
        'Year' => stamp.created_at.year,
        'Month' => stamp.created_at.month,
        'Consortium' => stamp.mi_attempt.mi_plan.consortium.name,
        'Gene id' => stamp.mi_attempt.mi_plan.gene_id,
        'Status' => stamp.mi_attempt_status.description
      }
      #break if LIMIT && table.data.size > LIMIT
    end

    grouped_report = Grouping( table, :by => [ 'Year', 'Month' ], :order => :name )
    
    return grouped_report
  end

  def self.generate_plans(request = nil, params={})
    
    headings = ['Year', 'Month', 'Consortium', 'Gene id', 'Status']
    table = Table(headings)
    
    MiPlan::StatusStamp.all.each do |stamp|
      table << {
        'Year' => stamp.created_at.year,
        'Month' => stamp.created_at.month,
        'Consortium' => stamp.mi_plan.consortium.name,
        'Gene id' => stamp.mi_plan.gene_id,
        'Status' => stamp.status.name
      }
      break if LIMIT && table.data.size > LIMIT
    end
    
    return table
  end

  #def self.generate(request = nil, params={})
  #  report = MiPlan::StatusStamp.report_table( :all )
  #  return report
  #end

  #def self.generate(request = nil, params={})
  #  mi_plans = MiPlan::StatusStamp.all
  #  report = mi_plans.first.report_table( :all )
  #  raise report.inspect
  #  return report
  #end

  def self.generate_original
    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
    table = Table(['Year', 'Month', 'Consortium', 'All', 'es_qcs', 'es_confirms', 'es_fails'])
    table2 = Table(['Year', 'Month', 'Consortium', 'All', 'mis', 'gc', 'abort'])
    table3 = Table(['Year', 'Month', 'Consortium', 'es_qcs', 'es_confirms', 'es_fails', 'mis', 'gc', 'abort'])

    MiPlan::StatusStamp.all.each do |stamp|
      year = stamp.created_at.year
      month = stamp.created_at.month
      consortium = stamp.mi_plan.consortium.name
      next unless (consortium == 'BaSH' || consortium == 'DTCC' || consortium == 'JAX')
      gene_id = stamp.mi_plan.gene_id
      status = stamp.status.name
      #puts "#{stamp.id} #{year} #{month} #{status}"
      summary[year][month][consortium][:all][gene_id] = 1
    
      if(status == 'Assigned - ES Cell QC In Progress')
        summary[year][month][consortium][:es_qcs][gene_id] = 1
      end
    
      if(status == 'Assigned - ES Cell QC Complete')
        summary[year][month][consortium][:es_qcs][gene_id] = 1
        summary[year][month][consortium][:es_confirms][gene_id] = 1
      end
    
      if(status == 'Aborted - ES Cell QC Failed')
        summary[year][month][consortium][:es_qcs][gene_id] = 1
        summary[year][month][consortium][:es_fails][gene_id] = 1
      end
    
      #puts "#{stamp.mi_plan.consortium.name}, #{stamp.status.name}, #{stamp.created_at.month}"
    end
    
    puts "doing attempts" if VERBOSE
    
    MiAttempt::StatusStamp.all.each do |stamp|
      year = stamp.created_at.year
      month = stamp.created_at.month
      plan = stamp.mi_attempt.mi_plan
      consortium = stamp.mi_attempt.mi_plan.consortium.name
      next unless (consortium == 'BaSH' || consortium == 'DTCC' || consortium == 'JAX')
      gene_id = plan.gene_id
      status = stamp.mi_attempt_status.description
      #puts "#{stamp.id} #{year} #{month} #{status}"
    
      if(status == 'Micro-injection in progress')
        summary[year][month][consortium][:mi][gene_id] = 1
      end
    
      if(status == 'Genotype confirmed')
        summary[year][month][consortium][:mi][gene_id] = 1
        summary[year][month][consortium][:gc][gene_id] = 1
      end
    
      if(status == 'Micro-injection aborted')
        summary[year][month][consortium][:mi][gene_id] = 1
        summary[year][month][consortium][:abort][gene_id] = 1
      end
    end
    
    summary.keys.sort.reverse!.each do |year|
      puts "" if VERBOSE
      puts "" if VERBOSE
      puts year
      month_hash = summary[year]
      month_hash.keys.sort.reverse!.each do |month|
        puts "" if VERBOSE
        puts month if VERBOSE
        cons_hash = month_hash[month]
        cons_hash.keys.sort.each do |cons|
          status_hash = cons_hash[cons]
          all = status_hash[:all].keys.size
          es_qcs = status_hash[:es_qcs].keys.size
          es_confirms = status_hash[:es_confirms].keys.size
          es_fails = status_hash[:es_fails].keys.size
          puts "#{cons},#{all},#{es_qcs},#{es_confirms},#{es_fails}" if VERBOSE
          table << {
            'Year' => year,
            'Month' => Date::MONTHNAMES[month],
            'Consortium' => cons, 'All' => all, 'es_qcs' => es_qcs, 'es_confirms' => es_confirms, 'es_fails' => es_fails
          }
        end
      end
    end
    
    summary.keys.sort.reverse!.each do |year|
      puts "" if VERBOSE
      puts year if VERBOSE
      month_hash = summary[year]
      month_hash.keys.sort.reverse!.each do |month|
        puts "" if VERBOSE
        puts "" if VERBOSE
        puts month if VERBOSE
        cons_hash = month_hash[month]
        cons_hash.keys.sort.each do |cons|
          status_hash = cons_hash[cons]
          all = status_hash[:all].keys.size
          mis = status_hash[:mi].keys.size
          gc = status_hash[:gc].keys.size
          abort = status_hash[:abort].keys.size

          es_qcs = status_hash[:es_qcs].keys.size
          es_confirms = status_hash[:es_confirms].keys.size
          es_fails = status_hash[:es_fails].keys.size

          puts "#{cons},#{all},#{mis},#{gc},#{abort}" if VERBOSE
          table2 << {
            'Year' => year,
            'Month' => Date::MONTHNAMES[month],
            'Consortium' => cons,
            'All' => all,
            'mis' => mis,
            'gc' => gc,
            'abort' => abort
          }
          table3 << {
            'Year' => year,
            'Month' => Date::MONTHNAMES[month],
            'Consortium' => cons,
            #'All' => all,
            'es_qcs' => es_qcs, 'es_confirms' => es_confirms, 'es_fails' => es_fails,
            'mis' => mis,
            'gc' => gc,
            'abort' => abort
          }
        end
      end
    end

    grouped_report = Grouping( table, :by => [ 'Year' ], :order => :name )
    grouped_report2 = Grouping( table2, :by => [ 'Year' ], :order => :name )
    grouped_report3 = Grouping( table3, :by => [ 'Year' ], :order => :name )

    table4 = table3.pivot('Month', :group_by => "Year", :values => 'Consortium' )
    
    # try to create an object that has the same interface as a ruport object
    # i.e. to_html/to_csv
    # we can then maintain same interface in controller/view
    
    wrapper = Class.new do
      @table = nil
      def to_csv
        raise "Not Yet Implemented!"
      end
      def to_html
        @table.to_html
      end
      def set_table(new_table)
        @table = new_table
      end
    end
    
    proxy = wrapper.new
    proxy.set_table(table4)
    
    return [grouped_report, grouped_report2, grouped_report3, table4, table3, proxy]
  end
  
end
