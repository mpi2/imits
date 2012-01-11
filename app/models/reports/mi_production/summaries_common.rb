# encoding: utf-8

module Reports::MiProduction::SummariesCommon

  include Reports::Helper
  include ActionView::Helpers::UrlHelper
  include Reports::MiProduction::Helper
  
  DEBUG = false      
  CSV_LINKS = true  
  ORDER_BY_MAP = { 'Low' => 3, 'Medium' => 2, 'High' => 1}
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
    'ES QC failed' => ['Aborted - ES Cell QC Failed'],
    'Registered for Phenotyping' => []
  }

  def subsummary_common(request, params)
    consortium = params[:consortium]
    type = params[:type]
    type = type ? type.gsub(/^\#\s+/, "") : nil
    priority = params[:priority]
    subproject = params[:subproject]    
    pcentre = params[:pcentre]    
  
    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table
      
    counter = 1
    report = Table(:data => cached_report.data,
      :column_names => cached_report.column_names,
      :filters => lambda {|r|
        if type != 'Languishing'
          return r['Consortium'] == consortium &&
            (pcentre.nil? || r['Production Centre'] == pcentre) &&
            (priority.nil? || r['Priority'] == priority) &&
            (type.nil? || (type == 'All' && all(r)) || (type == 'Registered for Phenotyping' && registered_for_phenotyping(r)) || MAPPING_SUMMARIES[type].include?(r.data['Overall Status'])) &&
            (subproject.nil? || r['Sub-Project'] == subproject)
        else
          return r['Consortium'] == consortium &&
            (pcentre.nil? || r['Production Centre'] == pcentre) &&
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
   
  def efficiency(request, row)
    glt = Integer(row['Genotype Confirmed Mice'])
    failures = Integer(row['Languishing']) + Integer(row['MI Aborted'])
    total = Integer(row['Genotype Confirmed Mice']) + failures
    pc = total != 0 ? (glt.to_f / total.to_f) * 100.0 : 0
    pc = pc != 0 ? "%i" % pc : request && request.format != :csv ? '' : 0
    return pc
  end

  def languishing(row)
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

  def all(row)
    return true
  end
    
end
