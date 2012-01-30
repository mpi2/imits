# encoding: utf-8

# TODO:unlimit consortia
# TODO: make prettify core generic
# TODO:phenotyping stamps
# TODO:

class Reports::MiProduction::SummaryMonthByMonthActivity
  
  def self.generate(request = nil, params={})
    table = params['table'].blank? ? 1 : params['table'].to_i
    tables = generate_summary
    return table > -1 && table < tables.size ? tables[table] : nil
  end

  def self.generate_summary
    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }

    MiPlan::StatusStamp.all.each do |stamp|
      year = stamp.created_at.year
      month = stamp.created_at.month
      consortium = stamp.mi_plan.consortium.name
      pcentre = stamp.mi_plan.production_centre && stamp.mi_plan.production_centre.name ? stamp.mi_plan.production_centre.name : ''
      next if pcentre.blank? || pcentre.to_s.length < 1
      next unless (consortium == 'BaSH' || consortium == 'DTCC' || consortium == 'JAX')
      gene_id = stamp.mi_plan.gene_id
      status = stamp.status.name
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
    end
        
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
    
    # try to create an object that has the same interface as a ruport Table class
    # i.e. to_html/to_csv
    # we can then maintain same interface in controller/view
    
    wrapper = Class.new do
      @table = nil
      @string = nil
      def to_csv
        @table.to_csv
      end
      def to_html
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
    table, string = prettify(summary)
    proxy.set_table(table)
    proxy.set_html(string)

    return [table, proxy]
  end

  def self.prettify(summary)
    string = ''
    string += '<table>'
    string += '<tr>'

    report_table = Table(['Year', 'Month', 'Consortium', 'Production Centre', 
      'es_qcs', 'es_confirms', 'es_fails', 
      'mis', 'gc', 'abort'
      ])

    report_table.column_names.each { |name| string += "<th>#{name}</th>" }

    summary.keys.sort.reverse!.each do |year|      
      string += '</tr>'
      year_count = 0
      string += '<tr>'
      string += "<td rowspan='YEAR_ROWSPAN'>#{year}</td>"
      month_hash = summary[year]
      month_hash.keys.sort.reverse!.each do |month|
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

            string += "<td>#{es_qcs}</td>"
            string += "<td>#{es_confirms}</td>"
            string += "<td>#{es_fails}</td>"
            
            string += "<td>#{mis}</td>"
            string += "<td>#{gc}</td>"
            string += "<td>#{abort}</td>"
            
            string += "</tr>\n"
            year_count += 1
            month_count += 1

            report_table << {
              'Year' => year,
              'Month' => month,
              'Consortium' => cons,
              'Production Centre' => centre,
              'es_qcs' => es_qcs,
              'es_confirms' => es_confirms,
              'es_fails' => es_fails,
              'mis' => mis,
              'gc' => gc,
              'abort' => abort
            }

          end
          string = string.gsub(/CONS_ROWSPAN/, centre_hash.keys.size.to_s)
        end
        string = string.gsub(/MONTH_ROWSPAN/, month_count.to_s)
      end
      string = string.gsub(/YEAR_ROWSPAN/, year_count.to_s)
    end
    string += '</table>'
    return report_table, string
  end
    
end
