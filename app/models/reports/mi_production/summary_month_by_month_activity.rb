# encoding: utf-8

# TODO: use proper names in summary hashes
# TODO: add cell links

class Reports::MiProduction::SummaryMonthByMonthActivity
  
  CSV_BLANKS = true

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
  HEADINGS_MAP = {}
  HEADINGS.each { |name| HEADINGS_MAP[name] = name }
  HEADINGS_MAP_INVERTED = HEADINGS_MAP.invert
  HEADINGS_CLEAN = []
  HEADINGS.each { |name| HEADINGS_CLEAN.push(HEADINGS_MAP[name]) }

  def self.generate(request = nil, params={}, consortia = ['BaSH', 'DTCC', 'JAX'])
    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }

    MiPlan::StatusStamp.all.each do |stamp|
      
      next if stamp.created_at < 6.months.ago.to_date
      
      year = stamp.created_at.year
      month = stamp.created_at.month
      consortium = stamp.mi_plan.consortium.name
      pcentre = stamp.mi_plan.production_centre && stamp.mi_plan.production_centre.name ? stamp.mi_plan.production_centre.name : ''
      next if pcentre.blank? || pcentre.to_s.length < 1
      next if consortia && ! consortia.include?(consortium)
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

      next if stamp.created_at < 6.months.ago.to_date

      year = stamp.created_at.year
      month = stamp.created_at.month
      plan = stamp.mi_attempt.mi_plan
      consortium = stamp.mi_attempt.mi_plan.consortium.name
      pcentre = stamp.mi_attempt.production_centre_name
      next if pcentre.blank? || pcentre.to_s.length < 1
      next if consortia && ! consortia.include?(consortium)
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
    
    PhenotypeAttempt::StatusStamp.all.each do |stamp|

      next if stamp.created_at < 6.months.ago.to_date

      year = stamp.created_at.year
      month = stamp.created_at.month
	  
      consortium = stamp.phenotype_attempt.mi_plan.consortium.name
      
      pcentre = stamp.phenotype_attempt.mi_plan.production_centre && stamp.phenotype_attempt.mi_plan.production_centre.name ? 
        stamp.phenotype_attempt.mi_plan.production_centre.name : ''
      
      next if pcentre.blank?
      next if consortia && ! consortia.include?(consortium)
      gene_id = stamp.phenotype_attempt.mi_plan.gene_id
      status = stamp.phenotype_attempt.status.name

    if status == 'Phenotype Attempt Aborted'
      summary[year][month][consortium][pcentre]['Phenotype Attempt Aborted'][gene_id] = 1
    end
    
    if status == 'Phenotyping Complete'
      summary[year][month][consortium][pcentre]['Phenotyping Complete'][gene_id] = 1
    end
    
    if status == 'Phenotyping Started' || status == 'Phenotyping Complete'
      summary[year][month][consortium][pcentre]['Phenotyping Started'][gene_id] = 1
    end
    
    if status == 'Cre Excision Complete' || status == 'Phenotyping Started' || status == 'Phenotyping Complete'
      summary[year][month][consortium][pcentre]['Cre Excision Complete'][gene_id] = 1
    end
    
    if status == 'Cre Excision Started' || status == 'Cre Excision Complete' || status == 'Phenotyping Started' || status == 'Phenotyping Complete'
      summary[year][month][consortium][pcentre]['Cre Excision Started'][gene_id] = 1
    end
    
    if status == 'Rederivation Started'
      summary[year][month][consortium][pcentre]['Rederivation Started'][gene_id] = 1
    end
    
    if status == 'Rederivation Complete'
      summary[year][month][consortium][pcentre]['Rederivation Complete'][gene_id] = 1
    end
    
    if status == 'Phenotype Attempt Registered' || status == 'Cre Excision Started' || status == 'Cre Excision Complete' || status == 'Phenotyping Started' || status == 'Phenotyping Complete' ||
      status == 'Rederivation Started' || status == 'Rederivation Complete'
      summary[year][month][consortium][pcentre]['Phenotype Attempt Registered'][gene_id] = 1
    end

    end

    table, html_string = prettify(request, params, summary)

    return { :csv => table.to_csv, :html => html_string}
  end

  def self.prettify(request, params, summary)
    string = ''
    string += '<table>'
    string += '<tr>'

    report_table = Table(HEADINGS_CLEAN)

    make_clean = lambda do |value|
      return value if request && request.format == :csv && ! CSV_BLANKS
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
              return frame[key] if request && request.format == :csv
              return '' if frame[key].to_s.length < 1
              return '' if frame[key].to_i == 0              
              consort = CGI.escape cons
              pcentre = CGI.escape centre
              pcentre = pcentre ? "&pcentre=#{pcentre}" : ''
              type = CGI.escape key
              separator = /\?/.match(script_name) ? '&' : '?'
              return "<a href='#{script_name}#{separator}consortium=#{consort}#{pcentre}&type=#{type}'>#{frame[key]}</a>"
            end
            
            status_hash = centre_hash[centre]
            
            array = [
              :es_qcs,
              :es_confirms,
              :es_fails,
              :mi,
              :gc,
              :abort,
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
            
            array.each { |name| string += "<td>#{make_clean.call status_hash[name].keys.size}</td>" }

            string += "</tr>\n"
            year_count += 1
            month_count += 1

            hash = {
              'Year' => year,
              'Month' => month,
              'Consortium' => cons,
              'Production Centre' => centre,
              'ES Cell QC In Progress' => make_clean.call(status_hash[:es_qcs].keys.size),
              'ES Cell QC Complete' => make_clean.call(status_hash[:es_confirms].keys.size),
              'ES Cell QC Failed' => make_clean.call(status_hash[:es_fails].keys.size),
              'Micro-injection in progress' => make_clean.call(status_hash[:mis].keys.size),
              'Genotype confirmed' => make_clean.call(status_hash[:gc].keys.size),
              'Micro-injection aborted' => make_clean.call(status_hash[:abort].keys.size)
            }

            array = [
              'Phenotype Attempt Registered',
              'Rederivation Started',
              'Rederivation Complete',
              'Cre Excision Started',
              'Cre Excision Complete',
              'Phenotyping Started',
              'Phenotyping Complete',
              'Phenotype Attempt Aborted'
            ]

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
    
end
