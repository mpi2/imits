# encoding: utf-8

# TODO: what about empty centres?
# TODO: better rowspanning
# TODO: iterator for test data
# TODO: add details flag

class Reports::MiProduction::SummaryMonthByMonthActivity
  
  DEBUG = true
  CSV_BLANKS = false
  CUT_OFF_DATE = Date.parse('2011-08-01')

  PLAN_STATUSES = ['ES Cell QC In Progress', 'ES Cell QC Complete', 'ES Cell QC Failed']
  ATTEMPT_STATUSES = ['Micro-injection in progress', 'Genotype confirmed', 'Micro-injection aborted']
  PHENOTYPE_STATUSES = [
    'Phenotype Attempt Aborted',
    'Phenotyping Complete',
    'Phenotyping Started',
    'Cre Excision Complete',
    'Cre Excision Started',
    'Rederivation Started',
    'Rederivation Complete',
    'Phenotype Attempt Registered'
  ]

  HEADINGS = [
    'Year',
    'Month',
    'Consortium',
    'Production Centre', 
    'ES Cell QC In Progress',
    'ES Cell QC Complete',
    'ES Cell QC Failed',
    'Micro-injection in progress',
    'Genotype confirmed',
    'Micro-injection aborted',
    'Phenotype Attempt Registered',
    'Rederivation Started',
    'Rederivation Complete',
    'Cre Excision Started',
    'Cre Excision Complete',
    'Phenotyping Started',
    'Phenotyping Complete',
    'Phenotype Attempt Aborted'
  ]
  
  def self.generate(params)

    if params[:consortium]
      title, table = subsummary(params)
      return { :csv => table.to_csv, :html => table.to_html, :title => title,
        :table => table # for test
      }
    end
    
    summary = get_summary(params)

    table, html_string = prettify(params, summary)
    
    title = params[:komp2] ? 'KOMP2 Summary Month by Month' : 'All Consortia Summary Month by Month'

    return { :csv => table.to_csv, :html => html_string, :title => title,
      :table => table # for test
    }
  end

  def self.prettify(params, summary)
    string = ''
    string += '<table>'
    string += '<tr>'

    script_name = params[:script_name]

    report_table = Table(HEADINGS)

    make_clean = lambda do |value|
      return value if params[:format] == :csv && ! CSV_BLANKS
      return '' if value.to_s.length < 1
      return '' if value.to_i == 0
      return value
    end
        
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
            
            make_link = lambda do |key, frame|
              return frame[key].keys.size if params[:format] == :csv
              return '' if frame[key].keys.size.to_s.length < 1
              return '' if frame[key].keys.size.to_i == 0              
              consort = CGI.escape cons
              pcentre = CGI.escape centre
              type = CGI.escape key.to_s
              separator = /\?/.match(script_name) ? '&' : '?'
              return "<a href='#{script_name}#{separator}year=#{year}&month=#{month}&consortium=#{consort}&pcentre=#{pcentre}&type=#{type}'>#{frame[key].keys.size}</a>"
            end
            
            status_hash = centre_hash[centre]
            
            array = [
              'ES Cell QC In Progress',
              'ES Cell QC Complete',
              'ES Cell QC Failed',
              'Micro-injection in progress',
              'Genotype confirmed',
              'Micro-injection aborted',
              'Phenotype Attempt Registered',
              'Rederivation Started',
              'Rederivation Complete',
              'Cre Excision Started',
              'Cre Excision Complete',
              'Phenotyping Started',
              'Phenotyping Complete',
              'Phenotype Attempt Aborted'
            ]

            string += "<td>#{centre}</td>"
            
            array.each { |name| string += "<td>#{make_link.call(name, status_hash)}</td>" }

            string += "</tr>\n"
            year_count += 1
            month_count += 1

            hash = {
              'Year' => year,
              'Month' => month,
              'Consortium' => cons,
              'Production Centre' => centre
            }

            array.each { |name| hash[name] = make_clean.call(status_hash[name].keys.size) }

            report_table << hash

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
  
  def self.subsummary(params)
        
    consortium = params[:consortium]
    type = params[:type]
    pcentre = params[:pcentre]
    year = params[:year]
    month = params[:month]

    summary = get_summary(params)
    
    table = Table(["Date", "Marker Symbol", "Consortium", "Centre", "Status"])
    
    summary[year.to_i][month.to_i][consortium][pcentre][type].keys.each do |gene|
      table << {
        "Date" => summary[year.to_i][month.to_i][consortium][pcentre][type][gene][:date].strftime("%Y-%m-%d"),
        "Consortium"=> consortium,
        "Centre"=>pcentre,
        "Marker Symbol" => summary[year.to_i][month.to_i][consortium][pcentre][type][gene][:symbol],
        "Status" => summary[year.to_i][month.to_i][consortium][pcentre][type][gene][:status]
      }
    end

    table.sort_rows_by!("Date", :order => :descending)
  
    title = "Plan Details" if PLAN_STATUSES.include? type
    title = "Attempt Details" if ATTEMPT_STATUSES.include? type
    title = "Phenotype Details" if PHENOTYPE_STATUSES.include? type
    title += " - YEAR: #{year} - MONTH: #{month} - CONSORTIUM: #{consortium} - CENTRE: #{pcentre} - TYPE: #{type} (#{table.data.size})" if DEBUG
    
    return title, table
  end
  
  def self.get_summary(params)
    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
    
    consortia = params && params[:komp2] ? ['BaSH', 'DTCC', 'JAX'] : nil
    
    type = params[:type]
            
    if ! type || PLAN_STATUSES.include?(type)
          
      MiPlan::StatusStamp.all.each do |stamp|
      
        next if consortia && stamp.created_at < CUT_OFF_DATE
      
        year = stamp.created_at.year
        month = stamp.created_at.month
        day = stamp.created_at.month
        consortium = stamp.mi_plan.consortium.name
        pcentre = stamp.mi_plan.production_centre && stamp.mi_plan.production_centre.name ? stamp.mi_plan.production_centre.name : ''
        pcentre = 'UNKNOWN' if pcentre.blank? || pcentre.to_s.length < 1
        next if consortia && ! consortia.include?(consortium)
        gene_id = stamp.mi_plan.gene_id
        status = stamp.status.name
        marker_symbol = stamp.mi_plan.gene.marker_symbol
      
        details_hash = { :symbol => marker_symbol, :status => status, :date => stamp.created_at }

        if(status == 'Assigned - ES Cell QC In Progress')
          summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
        end
    
        if(status == 'Assigned - ES Cell QC Complete')
          summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
          summary[year][month][consortium][pcentre]['ES Cell QC Complete'][gene_id] = details_hash
        end
    
        if(status == 'Aborted - ES Cell QC Failed')
          summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
          summary[year][month][consortium][pcentre]['ES Cell QC Failed'][gene_id] = details_hash
        end
               
      end

      return summary if PLAN_STATUSES.include? type

    end
    
    if ! type || ATTEMPT_STATUSES.include?(type)

      MiAttempt::StatusStamp.all.each do |stamp|

        next if consortia && stamp.created_at < CUT_OFF_DATE

        year = stamp.created_at.year
        month = stamp.created_at.month
        day = stamp.created_at.day
        consortium = stamp.mi_attempt.mi_plan.consortium.name
        pcentre = stamp.mi_attempt.production_centre_name
        pcentre = 'UNKNOWN' if pcentre.blank? || pcentre.to_s.length < 1
        next if consortia && ! consortia.include?(consortium)
        gene_id = stamp.mi_attempt.mi_plan.gene_id
        status = stamp.mi_attempt_status.description
        marker_symbol = stamp.mi_attempt.mi_plan.gene.marker_symbol

        details_hash = {
          :symbol => marker_symbol,
          :status => stamp.mi_attempt.mi_plan.latest_relevant_mi_attempt.mi_attempt_status.description,
          :date => stamp.mi_attempt.mi_plan.latest_relevant_mi_attempt.mi_attempt_status.created_at
        }
          
        if(status == 'Micro-injection in progress')
          summary[year][month][consortium][pcentre]['Micro-injection in progress'][gene_id] = details_hash
        end
    
        if(status == 'Genotype confirmed')
          summary[year][month][consortium][pcentre]['Micro-injection in progress'][gene_id] = details_hash
          summary[year][month][consortium][pcentre]['Genotype confirmed'][gene_id] = details_hash
        end
    
        if(status == 'Micro-injection aborted')
          summary[year][month][consortium][pcentre]['Micro-injection in progress'][gene_id] = details_hash
          summary[year][month][consortium][pcentre]['Micro-injection aborted'][gene_id] = details_hash
        end
      
      end

      return summary if ATTEMPT_STATUSES.include? type
    
    end

    if ! type || PHENOTYPE_STATUSES.include?(type)
    
      PhenotypeAttempt::StatusStamp.all.each do |stamp|

        next if consortia && stamp.created_at < CUT_OFF_DATE

        year = stamp.created_at.year
        month = stamp.created_at.month
        day = stamp.created_at.day
	  
        consortium = stamp.phenotype_attempt.mi_plan.consortium.name
      
        pcentre = stamp.phenotype_attempt.mi_plan.production_centre && stamp.phenotype_attempt.mi_plan.production_centre.name ?
          stamp.phenotype_attempt.mi_plan.production_centre.name : ''
      
        pcentre = 'UNKNOWN' if pcentre.blank?
        next if consortia && ! consortia.include?(consortium)
        gene_id = stamp.phenotype_attempt.mi_plan.gene_id
        status = stamp.phenotype_attempt.status.name
        marker_symbol = stamp.phenotype_attempt.mi_plan.gene.marker_symbol

        details_hash = {
          :symbol => marker_symbol,
          :status => stamp.phenotype_attempt.mi_plan.latest_relevant_phenotype_attempt.status.name,
          :date => stamp.phenotype_attempt.mi_plan.latest_relevant_phenotype_attempt.status.created_at
        }

        if status == 'Phenotype Attempt Aborted'
          summary[year][month][consortium][pcentre]['Phenotype Attempt Aborted'][gene_id] = details_hash
        end
    
        if status == 'Phenotyping Complete'
          summary[year][month][consortium][pcentre]['Phenotyping Complete'][gene_id] = details_hash
        end
        
        phenotyping_started = [ 'Phenotyping Started', 'Phenotyping Complete' ]
    
        if phenotyping_started.include?(status)
          summary[year][month][consortium][pcentre]['Phenotyping Started'][gene_id] = details_hash
        end
    
        cre_excision_complete = phenotyping_started + [ 'Cre Excision Complete' ]

        if cre_excision_complete.include?(status)
          summary[year][month][consortium][pcentre]['Cre Excision Complete'][gene_id] = details_hash
        end
        
        cre_excision_started = cre_excision_complete + [ 'Cre Excision Started' ]
    
        if cre_excision_started.include?(status)
          summary[year][month][consortium][pcentre]['Cre Excision Started'][gene_id] = details_hash
        end
        
        rederivation_started = cre_excision_started + [ 'Rederivation Started' ]
    
        if rederivation_started.include?(status)
          summary[year][month][consortium][pcentre]['Rederivation Started'][gene_id] = details_hash
          #TODO: check
        end

        rederivation_complete = rederivation_started + [ 'Rederivation Complete' ]
    
        if rederivation_complete.include?(status)
          summary[year][month][consortium][pcentre]['Rederivation Complete'][gene_id] = details_hash
          #TODO: check
        end

        phenotype_attempt_registered = rederivation_complete + [ 'Phenotype Attempt Registered' ]
    
        if phenotype_attempt_registered.include?(status)
          summary[year][month][consortium][pcentre]['Phenotype Attempt Registered'][gene_id] = details_hash
        end

      end

      return summary if PHENOTYPE_STATUSES.include? type
    
    end

    return summary
  end

  #class String
  #  def each_word
  #    self.split.each { |word| yield word }
  #  end
  #end
  
  #class PlanIterator
  #  def self.get_plans_summary(summary = nil)
  #    summary = summary ? summary : Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
  #
  #    MiPlan::StatusStamp.all.each do |stamp|
  #    
  #      next if consortia && stamp.created_at < CUT_OFF_DATE
  #    
  #      year = stamp.created_at.year
  #      month = stamp.created_at.month
  #      day = stamp.created_at.month
  #      consortium = stamp.mi_plan.consortium.name
  #      pcentre = stamp.mi_plan.production_centre && stamp.mi_plan.production_centre.name ? stamp.mi_plan.production_centre.name : ''
  #      pcentre = 'UNKNOWN' if pcentre.blank? || pcentre.to_s.length < 1
  #      next if consortia && ! consortia.include?(consortium)
  #      gene_id = stamp.mi_plan.gene_id
  #      status = stamp.status.name
  #      marker_symbol = stamp.mi_plan.gene.marker_symbol
  #    
  #      details_hash = { :symbol => marker_symbol, :status => status, :date => stamp.created_at }
  #
  #      if(status == 'Assigned - ES Cell QC In Progress')
  #        summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
  #      end
  #  
  #      if(status == 'Assigned - ES Cell QC Complete')
  #        summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
  #        summary[year][month][consortium][pcentre]['ES Cell QC Complete'][gene_id] = details_hash
  #      end
  #  
  #      if(status == 'Aborted - ES Cell QC Failed')
  #        summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
  #        summary[year][month][consortium][pcentre]['ES Cell QC Failed'][gene_id] = details_hash
  #      end
  #             
  #    end
  #  end
  #  return summary
  #end
  #
  #def self.each_plan
  #  MiPlan::StatusStamp.all.each do |stamp|
  #            
  #    hash = {}
  #    
  #    hash[:year] = stamp.created_at.year
  #    hash[:month] = stamp.created_at.month
  #    hash[:day] = stamp.created_at.day
  #    hash[:consortium] = stamp.mi_plan.consortium.name
  #    hash[:pcentre] = stamp.mi_plan.production_centre && stamp.mi_plan.production_centre.name ? stamp.mi_plan.production_centre.name : 'UNKNOWN'
  #    
  #    gene_id = stamp.mi_plan.gene_id
  #    hash[:status] = stamp.status.name
  #    hash[:marker_symbol] = stamp.mi_plan.gene.marker_symbol
  #    hash[:created_at] = stamp.created_at
  #              
  #    yield hash
  #             
  #  end
  #end
  #
end
