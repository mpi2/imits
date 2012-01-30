# encoding: utf-8

class Reports::MiProduction::SummaryMonthByMonthActivity
  
  LIMIT = 10
  VERBOSE = false

  def self.generate(request = nil, params={})
    table = params['table'].blank? ? 0 : params['table'].to_i
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
 
  #def self.generate_attempts(request = nil, params={})
  #  
  #  headings = ['Year', 'Month', 'Consortium', 'Gene id', 'Status']
  #  table = Table(headings)
  #  
  #  MiAttempt::StatusStamp.all.each do |stamp|
  #    table << {
  #      'Year' => stamp.created_at.year,
  #      'Month' => stamp.created_at.month,
  #      'Consortium' => stamp.mi_attempt.mi_plan.consortium.name,
  #      'Gene id' => stamp.mi_attempt.mi_plan.gene_id,
  #      'Status' => stamp.mi_attempt_status.description
  #    }
  #    #break if LIMIT && table.data.size > LIMIT
  #  end
  #
  #  grouped_report = Grouping( table, :by => [ 'Year', 'Month' ], :order => :name )
  #  
  #  return grouped_report
  #end

  #def self.generate_plans(request = nil, params={})
  #  
  #  headings = ['Year', 'Month', 'Consortium', 'Gene id', 'Status']
  #  table = Table(headings)
  #  
  #  MiPlan::StatusStamp.all.each do |stamp|
  #    table << {
  #      'Year' => stamp.created_at.year,
  #      'Month' => stamp.created_at.month,
  #      'Consortium' => stamp.mi_plan.consortium.name,
  #      'Gene id' => stamp.mi_plan.gene_id,
  #      'Status' => stamp.status.name
  #    }
  #    break if LIMIT && table.data.size > LIMIT
  #  end
  #  
  #  return table
  #end

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
    table = Table(['Year', 'Month', 'Consortium', 'Production Centre', 'All', 'es_qcs', 'es_confirms', 'es_fails'])
    table2 = Table(['Year', 'Month', 'Consortium', 'Production Centre', 'All', 'mis', 'gc', 'abort'])
    table3 = Table(['Year', 'Month', 'Consortium', 'Production Centre', 'es_qcs', 'es_confirms', 'es_fails', 'mis', 'gc', 'abort'])

    MiPlan::StatusStamp.all.each do |stamp|
      year = stamp.created_at.year
      month = stamp.created_at.month
      consortium = stamp.mi_plan.consortium.name
      #raise stamp.mi_plan.production_centre && stamp.mi_plan.production_centre.namw? .inspect
      pcentre = stamp.mi_plan.production_centre && stamp.mi_plan.production_centre.name ? stamp.mi_plan.production_centre.name : 'unknown'
      #next if pcentre.blank? || pcentre.to_s.length < 1
      next if pcentre.blank? || pcentre.to_s == 'unknown'
      #= stamp.mi_plan.production_centre
      #pcentre = 'dummy'
      next unless (consortium == 'BaSH' || consortium == 'DTCC' || consortium == 'JAX')
      gene_id = stamp.mi_plan.gene_id
      status = stamp.status.name
      #puts "#{stamp.id} #{year} #{month} #{status}"
      summary[year][month][consortium][pcentre][:all][gene_id] = 1
    
      if(status == 'Assigned - ES Cell QC In Progress')
        summary[year][month][consortium][pcentre][:es_qcs][gene_id] = 1
      end
    
      if(status == 'Assigned - ES Cell QC Complete')
        summary[year][month][consortium][pcentre][:es_qcs][gene_id] = 1
        summary[year][month][consortium][pcentre][:es_confirms][gene_id] = 1
      end
    
      if(status == 'Aborted - ES Cell QC Failed')
        summary[year][month][consortium][pcentre][:es_qcs][gene_id] = 1
        summary[year][month][consortium][pcentre][:es_fails][gene_id] = 1
      end
    
      #puts "#{stamp.mi_plan.consortium.name}, #{stamp.status.name}, #{stamp.created_at.month}"
    end
    
    puts "doing attempts" if VERBOSE
    
    MiAttempt::StatusStamp.all.each do |stamp|
      year = stamp.created_at.year
      month = stamp.created_at.month
      plan = stamp.mi_attempt.mi_plan
      consortium = stamp.mi_attempt.mi_plan.consortium.name
      pcentre = stamp.mi_attempt.production_centre_name
      next if pcentre.blank? || pcentre.to_s.length < 1
      next unless (consortium == 'BaSH' || consortium == 'DTCC' || consortium == 'JAX')
      gene_id = plan.gene_id
      status = stamp.mi_attempt_status.description
      #puts "#{stamp.id} #{year} #{month} #{status}"
    
      if(status == 'Micro-injection in progress')
        summary[year][month][consortium][pcentre][:mi][gene_id] = 1
      end
    
      if(status == 'Genotype confirmed')
        summary[year][month][consortium][pcentre][:mi][gene_id] = 1
        summary[year][month][consortium][pcentre][:gc][gene_id] = 1
      end
    
      if(status == 'Micro-injection aborted')
        summary[year][month][consortium][pcentre][:mi][gene_id] = 1
        summary[year][month][consortium][pcentre][:abort][gene_id] = 1
      end
    end
    
    #summary.keys.each do |year|
    #  puts "" if VERBOSE
    #  puts "" if VERBOSE
    #  puts year
    #  month_hash = summary[year]
    #  month_hash.keys.each do |month|
    #    puts "" if VERBOSE
    #    puts month if VERBOSE
    #    cons_hash = month_hash[month]
    #    cons_hash.keys.each do |cons|
    #      centre_hash = cons_hash[cons]
    #      centre_hash.keys.each do |centre|
    #        next if centre.blank?
    #        status_hash = centre_hash[centre]
    #        all = status_hash[:all].keys.size
    #        es_qcs = status_hash[:es_qcs].keys.size
    #        es_confirms = status_hash[:es_confirms].keys.size
    #        es_fails = status_hash[:es_fails].keys.size
    #        puts "#{cons},#{all},#{es_qcs},#{es_confirms},#{es_fails}" if VERBOSE
    #        table << {
    #          'Year' => year,
    #          #              'Month' => Date::MONTHNAMES[month],
    #          'Month' => month,
    #          'Consortium' => cons,
    #          'Production Centre' => centre,
    #          'All' => all, 'es_qcs' => es_qcs, 'es_confirms' => es_confirms, 'es_fails' => es_fails
    #        }
    #      end
    #    end
    #  end
    #end
    
    #summary.keys.each do |year|
    #  puts "" if VERBOSE
    #  puts year if VERBOSE
    #  month_hash = summary[year]
    #  #month_hash.keys.each do |month|
    #  month_hash.keys.each do |month|
    #    puts "" if VERBOSE
    #    puts "" if VERBOSE
    #    puts month if VERBOSE
    #    cons_hash = month_hash[month]
    #    cons_hash.keys.each do |cons|
    #      centre_hash = cons_hash[cons]
    #      centre_hash.keys.each do |centre|
    #        next if centre.blank?
    #        status_hash = centre_hash[centre]
    #        all = status_hash[:all].keys.size
    #        mis = status_hash[:mi].keys.size
    #        gc = status_hash[:gc].keys.size
    #        abort = status_hash[:abort].keys.size
    #
    #        es_qcs = status_hash[:es_qcs].keys.size
    #        es_confirms = status_hash[:es_confirms].keys.size
    #        es_fails = status_hash[:es_fails].keys.size
    #
    #        puts "#{cons},#{all},#{mis},#{gc},#{abort}" if VERBOSE
    #        table2 << {
    #          'Year' => year,
    #          'Month' => month,
    #          'Consortium' => cons,
    #          'Production Centre' => centre,
    #          'All' => all,
    #          'mis' => mis,
    #          'gc' => gc,
    #          'abort' => abort
    #        }
    #        table3 << {
    #          'Year' => year,
    #          'Month' => month,
    #          'Consortium' => cons,
    #          'Production Centre' => centre,
    #          #'All' => all,
    #          'es_qcs' => es_qcs, 'es_confirms' => es_confirms, 'es_fails' => es_fails,
    #          'mis' => mis,
    #          'gc' => gc,
    #          'abort' => abort
    #        }
    #      end
    #    end
    #  end
    #end

    grouped_report = Grouping( table, :by => [ 'Year' ], :order => :name )
    grouped_report2 = Grouping( table2, :by => [ 'Year' ], :order => :name )
    grouped_report3 = Grouping( table3, :by => [ 'Year' ], :order => :name )

    table4 = table3.pivot('Month', :group_by => "Year", :values => 'Consortium' )
    
    # try to create an object that has the same interface as a ruport object
    # i.e. to_html/to_csv
    # we can then maintain same interface in controller/view
    
    wrapper = Class.new do
      @table = nil
      @string = nil
      def to_csv
        @table.to_csv
      end
      def to_html
        #@table.to_html
        @string
      end
      def set_table(new_table)
        @table = new_table
      end
      def set_html(string)
        @string = string
      end
    end
    
    proxy = wrapper.new
    proxy.set_table(table)
    proxy.set_html(prettify(table))
    
    proxy2 = wrapper.new
    proxy2.set_table(table)
    proxy2.set_html(prettify_new(table))
    
    proxy3 = wrapper.new
    proxy3.set_table(table)
    proxy3.set_html(prettify2(summary, table))
    
    proxy4 = wrapper.new
    proxy4.set_table(table)
    proxy4.set_html(prettify3(summary))
    
    return [grouped_report, grouped_report2, grouped_report3, table4, table3, proxy, proxy2, proxy3, proxy4]
  end

  def self.prettify(table)
    html_array = []
    grouped_report = Grouping( table, :by => [ 'Year', 'Month', 'Consortium', 'Production Centre' ], :order => :name )
  
    html_array.push '<table>'
    html_array.push '<tr>'
    table.column_names.each do |name|
      html_array.push "<th>#{name}</th>"
    end
    html_array.push '</tr>'
    
    grouped_report.each do |year|
      
      next if year != 2011
      
      html_array.push '<tr>'
      
      month_group = grouped_report.subgrouping(year)
      
#      size = 31 # month_group.data.size.to_s
      size = month_group.data.size.to_s
      #size = 44 #month_group.data.size
      
      html_array.push "<td rowspan='#{size}'>#{year}</td>"
      
      month_group.each do |month|
        
        consortium_group = month_group.subgrouping(month)
        
        #size = size.to_i-9	#consortium_group.data.size.to_s
        size = consortium_group.data.size.to_s
        
        html_array.push "<td rowspan='#{size}'>#{Date::MONTHNAMES[month]}</td>"
        
        consortium_group.each do |consortium|
          
          production_centre_group = consortium_group.subgrouping(consortium)
          
          size = production_centre_group.data.size.to_s
          
          html_array.push "<td rowspan='#{size}'>#{consortium}</td>"
          
          production_centre_group.each do |production_centre|
            
            #size = production_centre_group[production_centre].size.to_s
            
            #html_array.push "<td rowspan='#{size}'>#{production_centre}</td>"
            #
            ##raise production_centre_group[production_centre].inspect
            #production_centre_group[production_centre].column_names.each do |column_name|
            #  html_array.push "<td>#{production_centre_group[production_centre].column(column_name)[0]}</td>"
            #end
            
            html_array.push "<td>#{production_centre}</td>"
            production_centre_group[production_centre].column_names.each do |column_name|
              html_array.push "<td>#{production_centre_group[production_centre].column(column_name)[0]}</td>"
            end
            
            html_array.push '</tr>'
            #break
          end
          
          # html_array.push '</tr>'
        end
        
      end
      
      #break
    
    end
    
    html_array.push '</table>'
    #return table
    return html_array.join("\n")
  end

  # yeah, I know this is crap

  def self.prettify_new(table)
    html_array = []
    size_array = []
    grouped_report = Grouping( table, :by => [ 'Year', 'Month', 'Consortium', 'Production Centre' ], :order => :name )

    html_array.push '<table>'
    html_array.push '<tr>'
    table.column_names.each do |name|
      html_array.push "<th>#{name}</th>"
    end
    html_array.push '</tr>'
    
    grouped_report.each do |year|
      
      next if year != 2011
      
      html_array.push '<tr>'
      
      month_group = grouped_report.subgrouping(year)
      
      size1 = month_group.data.size
      
      html_array.push "<td rowspan='YEAR_#{year}'>#{year}</td>"
      
      month_group.each do |month|
        
        consortium_group = month_group.subgrouping(month)
        
        size2 = consortium_group.data.size
        
        html_array.push "<td rowspan='MONTH_#{year}_#{month}'>#{Date::MONTHNAMES[month]}</td>"
        
        consortium_group.each do |consortium|
          
          production_centre_group = consortium_group.subgrouping(consortium)
          
          size3 = production_centre_group.data.size
          
          html_array.push "<td rowspan='CONSORTIUM_#{year}_#{month}_#{consortium}'>#{consortium}</td>"
          
          production_centre_group.each do |production_centre|
            
            html_array.push "<td>#{production_centre}</td>"
            production_centre_group[production_centre].column_names.each do |column_name|
              html_array.push "<td>#{production_centre_group[production_centre].column(column_name)[0]}</td>"
            end
            
            html_array.push '</tr>'
          end
          
          hash = {}
          hash["YEAR_#{year}"] = size1 + size2 + size3
          hash["MONTH_#{year}_#{month}"] = size2 + size3
          hash["CONSORTIUM_#{year}_#{month}_#{consortium}"] = size3
          size_array.push hash
          
        end
        
      end
          
    end
    
    html_array.push '</table>'
    #return table
    string = html_array.join("\n")
    
    size_array.each do |item|
    	item.each_pair { |k, v| string = string.gsub(k, v.to_s) }
    end
    
    return string
  end
  
  def self.prettify2(summary, table)
    string = ''
    string += '<table>'
    string += '<tr>'
    table.column_names.each do |name|
      string += "<th>#{name}</th>"
    end

    summary.keys.sort.each do |year|
      string += '</tr>'
      row_count = 0
      string += '<tr>'
      string += "<td rowspan='YEAR_ROWSPAN'>#{year}</td>"
      month_hash = summary[year]
      month_hash.keys.sort.each do |month|
        string += "<td rowspan='MONTH_ROWSPAN'>#{month}</td>"
        cons_hash = month_hash[month]
        month_count = 0
        cons_hash.keys.each do |cons|
          centre_hash = cons_hash[cons]
          string += "<td rowspan='CONS_ROWSPAN'>#{cons}</td>"
          centre_hash.keys.each do |centre|
            next if centre.blank?
            status_hash = centre_hash[centre]
            all = status_hash[:all].keys.size
            es_qcs = status_hash[:es_qcs].keys.size
            es_confirms = status_hash[:es_confirms].keys.size
            es_fails = status_hash[:es_fails].keys.size
            puts "#{cons},#{all},#{es_qcs},#{es_confirms},#{es_fails}" if VERBOSE
            string += "<td>#{centre}</td>"
            string += "<td>#{all}</td>"
            string += "<td>#{es_qcs}</td>"
            string += "<td>#{es_confirms}</td>"
            string += "<td>#{es_fails}</td>"
            string += "</tr>\n"
            row_count += 1
            month_count += 1
          end
          string = string.gsub(/CONS_ROWSPAN/, centre_hash.keys.size.to_s)
        end
        #string = string.gsub(/MONTH_ROWSPAN/, row_count.to_s)
        string = string.gsub(/MONTH_ROWSPAN/, month_count.to_s)
      end
      string = string.gsub(/YEAR_ROWSPAN/, row_count.to_s)
    end
    string += '</table>'
    return string
  end

  def self.prettify3(summary)
    string = ''
    string += '<table>'
    string += '<tr>'

    column_names = ['Year', 'Month', 'Consortium', 'Production Centre',
                    'mi', 'gc', 'abort',
                    'es_qcs', 'es_confirms', 'es_fails']

    column_names.each do |name|
      string += "<th>#{name}</th>"
    end

    summary.keys.sort.each do |year|
      string += '</tr>'
      year_count = 0
      string += '<tr>'
      string += "<td rowspan='YEAR_ROWSPAN'>#{year}</td>"
      month_hash = summary[year]
      month_hash.keys.sort.each do |month|
        string += "<td rowspan='MONTH_ROWSPAN'>#{Date::MONTHNAMES[month]}</td>"
        cons_hash = month_hash[month]
        month_count = 0
        cons_hash.keys.each do |cons|
          centre_hash = cons_hash[cons]
          string += "<td rowspan='CONS_ROWSPAN'>#{cons}</td>"
          centre_hash.keys.each do |centre|
            next if centre.blank?
            status_hash = centre_hash[centre]

            es_qcs = status_hash[:es_qcs].keys.size
            es_confirms = status_hash[:es_confirms].keys.size
            es_fails = status_hash[:es_fails].keys.size

            mis = status_hash[:mi].keys.size
            gc = status_hash[:gc].keys.size
            abort = status_hash[:abort].keys.size

            string += "<td>#{centre}</td>"

            string += "<td>#{mis}</td>"
            string += "<td>#{gc}</td>"
            string += "<td>#{abort}</td>"
            
            string += "<td>#{es_qcs}</td>"
            string += "<td>#{es_confirms}</td>"
            string += "<td>#{es_fails}</td>"
            
            string += "</tr>\n"
            year_count += 1
            month_count += 1
          end
          string = string.gsub(/CONS_ROWSPAN/, centre_hash.keys.size.to_s)
        end
        string = string.gsub(/MONTH_ROWSPAN/, month_count.to_s)
      end
      string = string.gsub(/YEAR_ROWSPAN/, year_count.to_s)
    end
    string += '</table>'
    return string
  end
    
end
