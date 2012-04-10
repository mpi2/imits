# encoding: utf-8

class Reports::MiProduction::SummaryMonthByMonthActivityAllCentresImpc < Reports::Base

  DEBUG = false
  CSV_BLANKS = false
  CUT_OFF_DATE = Date.parse('2011-06-01')
  
#  328	56
#300	34
#252	16
#204	0
#156	0
#112	0
#68	0
#32	0
  MI_GOALS = 
    {
      2012 => {
        4 => {
          'BaSH' => 356,
          'DTCC' => 0,
          'JAX' => 75,
        },
        3 => {
          'BaSH' => 328,
          'DTCC' => 0,
          'JAX' => 45,
        },
        2 => {
          'BaSH' => 300,
          'DTCC' => 0,
          'JAX' => 15,
        },
        1 => {
          'BaSH' => 252,
          'DTCC' => 0,
          'JAX' => 6,
        }
      },
      2011 => {
        12 => {
          'BaSH' => 204,
          'DTCC' => 0,
          'JAX' => 0,
        },
        11 => {
          'BaSH' => 156,
          'DTCC' => 0,
          'JAX' => 0,
        },
        10 => {
          'BaSH' => 112,
          'DTCC' => 0,
          'JAX' => 0,
        },
        9 => {
          'BaSH' => 68,
          'DTCC' => 0,
          'JAX' => 0,
        },
        8 => {
          'BaSH' => 32,
          'DTCC' => 0,
          'JAX' => 0,
        },
        7 => {
          'BaSH' => 10,
          'DTCC' => 0,
          'JAX' => 0,
        },
        6 => {
          'BaSH' => 10,
          'DTCC' => 0,
          'JAX' => 0,
        }
      }
    }
  
  GC_GOALS = 
    {
      2012 => {
        4 => {
          'BaSH' => 78,
          'DTCC' => 0,
          'JAX' => 4,
        },
        3 => {
          'BaSH' => 56,
          'DTCC' => 0,
          'JAX' => 0,
        },
        2 => {
          'BaSH' => 34,
          'DTCC' => 0,
          'JAX' => 0,
        },
        1 => {
          'BaSH' => 16,
          'DTCC' => 0,
          'JAX' => 0,
        }
      },
      2011 => {
        12 => {
          'BaSH' => 0,
          'DTCC' => 0,
          'JAX' => 0,
        },
        11 => {
          'BaSH' => 0,
          'DTCC' => 0,
          'JAX' => 0,
        },
        10 => {
          'BaSH' => 0,
          'DTCC' => 0,
          'JAX' => 0,
        },
        9 => {
          'BaSH' => 0,
          'DTCC' => 0,
          'JAX' => 0,
        },
        8 => {
          'BaSH' => 0,
          'DTCC' => 0,
          'JAX' => 0,
        },
        7 => {
          'BaSH' => 0,
          'DTCC' => 0,
          'JAX' => 0,
        },
        6 => {
          'BaSH' => 0,
          'DTCC' => 0,
          'JAX' => 0,
        }
      }
    }
    
  HEADINGS_HTML = [
    'Year',
    'Month',
    'Consortium',

    'Cumulative ES Starts',
    'ES Cell QC In Progress',
    'ES Cell QC Complete',
    'ES Cell QC Failed',

    'Micro-injection in progress',
    'Cumulative MIs',
    'MI Goal',
    'Chimeras obtained',
    'Genotype confirmed',
    'Cumulative Genotype Confirmed',
    'GC Goal',
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

  HEADINGS_CSV = [
    'Year',
    'Consortium',

    'Cumulative ES Starts',
    'ES Cell QC In Progress',
    'ES Cell QC Complete',
    'ES Cell QC Failed',

    'Micro-injection in progress',
    'Cumulative MIs',
    'MI Goal',
    'Chimeras obtained',
    'Genotype confirmed',
    'Cumulative Genotype Confirmed',
    'GC Goal',
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
  
  def self.generate_details_for_cell (params = {})
    if params[:consortium]
      title, table = subsummary(params)
      return { :csv => table.to_csv, :html => table.to_html, :title => title, :table => table }
    end
  end
  
  def self.generate(params = {})

    summary = get_summary(params)
    
    html_string = convert_to_html(params, summary)

    table = convert_to_csv(params, summary)

    return { :csv => table.to_csv, :html => html_string, :table => table }
  end

  def self.add_cumulated_counts_and_monthly_goals(summary)
    current_totals_per_consortium = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
    Consortium.all.each do |consortium|
      current_totals_per_consortium[consortium.name][:es_starts] = 0
      current_totals_per_consortium[consortium.name][:mi_attempts] = 0
      current_totals_per_consortium[consortium.name][:gc_mice] = 0
    end
    
    summary.keys.sort.each do |year|
      month_hash = summary[year]
      month_hash.keys.sort.each do |month|
        cons_hash = month_hash[month]
        cons_hash.keys.sort.each do |consortium|
          
          total_es_starts =
            summary[year][month][consortium]['ALL']['ES Cell QC In Progress'].keys.size + 
            current_totals_per_consortium[consortium][:es_starts]
          
          current_totals_per_consortium[consortium][:es_starts] = total_es_starts
            
          total_mi_attempts = 
            summary[year][month][consortium]['ALL']['Micro-injection in progress'].keys.size + 
            current_totals_per_consortium[consortium][:mi_attempts]
          
          current_totals_per_consortium[consortium][:mi_attempts] = total_mi_attempts
          
          total_gc_mice = 
            summary[year][month][consortium]['ALL']['Genotype confirmed'].keys.size + 
            current_totals_per_consortium[consortium][:gc_mice]
          
          current_totals_per_consortium[consortium][:gc_mice] = total_gc_mice
            
          summary[year][month][consortium]['ALL']['Cumulative ES Starts'] = total_es_starts
          summary[year][month][consortium]['ALL']['Cumulative MIs'] = total_mi_attempts
          summary[year][month][consortium]['ALL']['Cumulative Genotype Confirmed'] = total_gc_mice
          
          summary[year][month][consortium]['ALL']['MI Goal'] = MI_GOALS[year][month][consortium]
          summary[year][month][consortium]['ALL']['GC Goal'] = GC_GOALS[year][month][consortium]
        end
      end
    end
  end

  def self.get_summary(params)

    summary = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }

    plan_map = Hash.new { |hash,key| raise("plan_map: No value defined for key: #{ key }") }
    MiPlan::Status.all.each { |i| plan_map[i.name.downcase.parameterize.underscore.to_sym] = i.name }

    attempt_map = Hash.new { |hash,key| raise("attempt_map: No value defined for key: #{ key }") }
    MiAttemptStatus.all.each { |i| attempt_map[i.description.downcase.parameterize.underscore.to_sym] = i.description }

    phenotype_map = Hash.new { |hash,key| raise("phenotype_map: No value defined for key: #{ key }") }
    PhenotypeAttempt::Status.all.each { |i| phenotype_map[i.name.downcase.parameterize.underscore.to_sym] = i.name }

    MiPlan::StatusStamp.all.each do |stamp|

      next if stamp.created_at < CUT_OFF_DATE

      year = stamp.created_at.year
      month = stamp.created_at.month
      day = stamp.created_at.day
      consortium = stamp.mi_plan.consortium.name
      pcentre = 'ALL'
      next if self.consortia && ! self.consortia.include?(consortium)
      gene_id = stamp.mi_plan.gene_id
      status = stamp.status.name
      marker_symbol = stamp.mi_plan.gene.marker_symbol

      details_hash = { :symbol => marker_symbol, :plan_id => stamp.mi_plan.id, :original_status => status, :original_date => stamp.created_at }

      self.consortia.each do |name|
        summary[year][month][name]['ALL']['ES Cell QC In Progress'] ||= {}
        summary[year][month][name]['ALL']['ES Cell QC Complete'] ||= {}
        summary[year][month][name]['ALL']['ES Cell QC Failed'] ||= {}
      end

      if status == plan_map[:assigned_es_cell_qc_in_progress]
        summary[year][month][consortium][pcentre]['ES Cell QC In Progress'][gene_id] = details_hash
      end

      if status == plan_map[:assigned_es_cell_qc_complete]
        summary[year][month][consortium][pcentre]['ES Cell QC Complete'][gene_id] = details_hash
      end

      if status == plan_map[:aborted_es_cell_qc_failed]
        summary[year][month][consortium][pcentre]['ES Cell QC Failed'][gene_id] = details_hash
      end

    end

    MiAttempt::StatusStamp.all.each do |stamp|

      next if stamp.created_at < CUT_OFF_DATE

      year = stamp.created_at.year
      month = stamp.created_at.month
      day = stamp.created_at.day
      consortium = stamp.mi_attempt.mi_plan.consortium.name
      pcentre = 'ALL'
      next if self.consortia && ! self.consortia.include?(consortium)
      gene_id = stamp.mi_attempt.mi_plan.gene_id
      status = stamp.mi_attempt_status.description
      marker_symbol = stamp.mi_attempt.mi_plan.gene.marker_symbol

      details_hash = { :symbol => marker_symbol, :plan_id => stamp.mi_attempt.mi_plan.id, :original_status => status, :original_date => stamp.created_at }

      self.consortia.each do |name|
        summary[year][month][name]['ALL']['Micro-injection in progress'] ||= {}
        summary[year][month][name]['ALL']['Genotype confirmed'] ||= {}
        summary[year][month][name]['ALL']['Micro-injection aborted'] ||= {}
        summary[year][month][name]['ALL']['Chimeras obtained'] ||= {}
      end

      if(status == attempt_map[:micro_injection_in_progress])
        summary[year][month][consortium][pcentre]['Micro-injection in progress'][gene_id] = details_hash
      end

      if(status == attempt_map[:chimeras_obtained])
        summary[year][month][consortium][pcentre]['Chimeras obtained'][gene_id] = details_hash
      end

      if(status == attempt_map[:genotype_confirmed])
        summary[year][month][consortium][pcentre]['Genotype confirmed'][gene_id] = details_hash
      end

      if(status == attempt_map[:micro_injection_aborted])
        summary[year][month][consortium][pcentre]['Micro-injection aborted'][gene_id] = details_hash
      end

    end

    PhenotypeAttempt::StatusStamp.all.each do |stamp|

      next if stamp.created_at < CUT_OFF_DATE

      year = stamp.created_at.year
      month = stamp.created_at.month
      day = stamp.created_at.day

      consortium = stamp.phenotype_attempt.mi_plan.consortium.name

      pcentre = stamp.phenotype_attempt.mi_plan.production_centre && stamp.phenotype_attempt.mi_plan.production_centre.name ?
        stamp.phenotype_attempt.mi_plan.production_centre.name : ''

      pcentre = 'ALL'
      next if self.consortia && ! self.consortia.include?(consortium)
      gene_id = stamp.phenotype_attempt.mi_plan.gene_id
      status = stamp.phenotype_attempt.status.name
      marker_symbol = stamp.phenotype_attempt.mi_plan.gene.marker_symbol

      details_hash = { :symbol => marker_symbol, :plan_id => stamp.phenotype_attempt.mi_plan.id, :original_status => status, :original_date => stamp.created_at }

      self.consortia.each do |name|
        summary[year][month][name]['ALL']['Phenotype Attempt Aborted'] ||= {}
      end

      if status == phenotype_map[:phenotype_attempt_aborted]
        summary[year][month][consortium][pcentre]['Phenotype Attempt Aborted'][gene_id] = details_hash
      end

      if status == phenotype_map[:phenotyping_complete]
        summary[year][month][consortium][pcentre]['Phenotyping Complete'][gene_id] = details_hash
      end

      if status == phenotype_map[:phenotyping_started]
        summary[year][month][consortium][pcentre]['Phenotyping Started'][gene_id] = details_hash
      end

      if status == phenotype_map[:cre_excision_complete]
        summary[year][month][consortium][pcentre]['Cre Excision Complete'][gene_id] = details_hash
      end

      if status == phenotype_map[:cre_excision_started]
        summary[year][month][consortium][pcentre]['Cre Excision Started'][gene_id] = details_hash
      end

      if status == phenotype_map[:rederivation_started]
        summary[year][month][consortium][pcentre]['Rederivation Started'][gene_id] = details_hash
      end

      if status == phenotype_map[:rederivation_complete]
        summary[year][month][consortium][pcentre]['Rederivation Complete'][gene_id] = details_hash
      end

      if status == phenotype_map[:phenotype_attempt_registered]
        summary[year][month][consortium][pcentre]['Phenotype Attempt Registered'][gene_id] = details_hash
      end

    end
    
    self.add_cumulated_counts_and_monthly_goals(summary)
    
    return summary
  end


  
  def self.convert_to_html(params, summary)

    script_name = params[:script_name]
    
    string = ''
    consortia_to_consider = []
    Consortium.all.each do |consortium|
      if(self.consortia)
        if self.consortia.include?(consortium.name)
          consortia_to_consider << consortium.name
        end
      else
        consortia_to_consider << consortium.name
      end
    end
    
    consortia_to_consider.each do |particular_consortium|
      string += '<table>'
      string += '<tr>'
      HEADINGS_HTML.each { |name| string += "<th>#{name}</th>" }
      summary.keys.sort.reverse!.each do |year|
  
        string += '</tr>'
        year_count = 0
        string += '<tr>'
        string += "<td class='report-cell-integer' rowspan='YEAR_ROWSPAN'>#{year}</td>"
        month_hash = summary[year]
        month_hash.keys.sort.reverse!.each do |month|
          string += "<td class='report-cell-text' rowspan='MONTH_ROWSPAN'>#{Date::MONTHNAMES[month]}</td>"
          
          month_count = 0
          cons_hash = month_hash[month]
  
          cons_hash.keys.sort.each do |cons|
            if(particular_consortium == cons)
              centre_hash = cons_hash[cons]
              string += "<td class='report-cell-text' rowspan='CONS_ROWSPAN'>#{cons}</td>"
    
              make_link = lambda do |key, value|
                return value if params[:format] == :csv
                return '' if value.to_s.length < 1
                return '' if value.to_i == 0
                consort = CGI.escape cons
                type = CGI.escape key.to_s
                separator = /\?/.match(script_name) ? '&' : '?'
                return "<a href='#{script_name}#{separator}year=#{year}&month=#{month}&consortium=#{consort}&type=#{type}'>#{value}</a>"
              end
    
              summer = {'ES Cell QC In Progress'=> 0, 'ES Cell QC Complete' => 0, 'ES Cell QC Failed' => 0}
              array2 = [ 'ES Cell QC In Progress', 'ES Cell QC Complete', 'ES Cell QC Failed' ]
              centre_hash.keys.each do |centre|
                status_hash = centre_hash[centre]
                array2.each do |name|
                  next if ! status_hash[name]
                  status_hash[name].each do |gene|
                    summer[name] += 1
                  end
                end
              end
    
                
              string += "<td class='report-cell-integer' rowspan='CONS_ROWSPAN'>#{centre_hash['ALL']["Cumulative ES Starts"]}</td>"
              array2.each { |name|
                string += "<td class='report-cell-integer' rowspan='CONS_ROWSPAN'>#{make_link.call(name, summer[name])}</td>"
              }
    
              centre_count = 0
    
              centre_hash.keys.sort.each do |centre|
    
                next if centre == 'ALL' && centre_hash.keys.size > 1
    
                centre_count += 1
    
                make_link = lambda do |key, frame|
                  return '' if ! frame[key]
                  return 0 if ! frame[key] && params[:format] == :csv
                  if(frame[key].class.name != "Hash")
                    return frame[key]
                  end
                  return frame[key].keys.size if params[:format] == :csv
                  return '' if frame[key].keys.size.to_s.length < 1
                  return '' if frame[key].keys.size.to_i == 0
    
                  consort = CGI.escape cons
                  pcentre = CGI.escape centre
                  type = CGI.escape key.to_s
                  separator = /\?/.match(script_name) ? '&' : '?'
                  return "<a href='#{script_name}#{separator}year=#{year}&month=#{month}&consortium=#{consort}&type=#{type}'>#{frame[key].keys.size}</a>"
                end
    
                status_hash = centre_hash[centre]
    
                array = [
                  'Micro-injection in progress',
                  'Cumulative MIs',
                  'MI Goal',
                  'Chimeras obtained',
                  'Genotype confirmed',
                  'Cumulative Genotype Confirmed',
                  'GC Goal',
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
    
                c = centre == 'ALL' ? '' : centre
    
                #string += "<td class='report-cell-text'>#{c}</td>"
    
                array.each { |name| string += "<td class='report-cell-integer'>#{make_link.call(name, status_hash)}</td>" }
    
                string += '</tr>' # this sometimes inserts empty rows
                string += '<tr>'
    
                year_count += 1
                month_count += 1
    
              end
              string = string.gsub(/CONS_ROWSPAN/, centre_count.to_s)
            end
          end
          string = string.gsub(/MONTH_ROWSPAN/, month_count.to_s)
        end
        string = string.gsub(/YEAR_ROWSPAN/, year_count.to_s)
      end
      string += '</table>'
  
      string = string.gsub(/\<tr\>\<\/tr\>/, '')
    end

    return string
  end

  def self.convert_to_csv(params, summary)
    
    column_names = [
      'Cumulative ES Starts',
      'ES Cell QC In Progress',
      'ES Cell QC Complete',
      'ES Cell QC Failed',
      'Micro-injection in progress',
      'Cumulative MIs',
      'MI Goal',
      'Chimeras obtained',
      'Genotype confirmed',
      'Cumulative Genotype Confirmed',
      'GC Goal',
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

    report_table = Table(HEADINGS_CSV)

    consortia_to_consider = []
    Consortium.all.each do |consortium|
      if(self.consortia)
        if self.consortia.include?(consortium.name)
          consortia_to_consider << consortium.name
        end
      else
        consortia_to_consider << consortium.name
      end
    end

    consortia_to_consider.each do |particular_consortium|
      summary.keys.sort.reverse!.each do |year|
        month_hash = summary[year]
        month_hash.keys.sort.reverse!.each do |month|
          cons_hash = month_hash[month]
          cons_hash.keys.sort.each do |cons|
            if(particular_consortium == cons)
              centre_hash = cons_hash[cons]
              centre_hash.keys.each do |centre|
                status_hash = centre_hash[centre]
    
                next if centre == 'ALL' && centre_hash.keys.size > 1
    
                #c = centre == 'ALL' ? '' : centre
                month_name = Date::MONTHNAMES[month]
    
                hash = {
                  #'Year' => year,
                  #'Month' => month,
                  'Year' => month_name + "-" + year.to_s,
                  'Consortium' => cons,
                  'Production Centre' => centre
                }
    
                column_names.each do |name|
                  if status_hash
                    if status_hash[name].class.name == "Hash"
                      hash[name] = status_hash[name] ? status_hash[name].keys.size : 0
                    else
                      hash[name] = status_hash[name]
                    end
                  else
                    hash[name] = 0
                  end
                end
    
                report_table << hash
              end
            end
          end
        end
      end
    end

    return report_table
  end

  def self.report_name; 'summary_month_by_month_activity_all_centres_impc'; end

  def initialize
    generated = self.class.generate
    @csv = generated[:csv]
    @html = generated[:html]
  end

  def to(format)
    if format == 'html'
      return @html
    elsif format == 'csv'
      return @csv
    end
  end

  def self.report_title; 'IMPC Summary Month by Month'; end
  def self.consortia; Consortium.all.map(&:name); end

end
