module ReportsHelper

  def reason_for_inspect_or_conflict(mi_plan, mi_plans)
    case mi_plan.status.name
    when 'Inspect - GLT Mouse'
      other_centres_consortia = MiPlan.scoped.where('mi_plans.gene_id = :gene_id AND mi_plans.id != :id',
        { :gene_id => mi_plan.gene_id, :id => mi_plan.id }).with_genotype_confirmed_mouse.map{ |p| "#{p.production_centre.name} (#{p.consortium.name})" }.uniq.sort
      return "GLT mouse produced at: #{other_centres_consortia.join(', ')}"
    when 'Inspect - MI Attempt'
      other_centres_consortia = MiPlan.scoped.where('gene_id = :gene_id AND id != :id',
        { :gene_id => mi_plan.gene_id, :id => mi_plan.id }).with_active_mi_attempt.map{ |p| "#{p.production_centre.name} (#{p.consortium.name})" }.uniq.sort
      return "MI already in progress at: #{other_centres_consortia.join(', ')}"
    when 'Inspect - Conflict'
      other_consortia = MiPlan.where('gene_id = :gene_id AND id != :id',
        { :gene_id => mi_plan.gene_id, :id => mi_plan.id }).where(:status_id => MiPlan::Status.all_assigned ).without_active_mi_attempt.map{ |p| p.consortium.name }.uniq.sort
      return "Other 'Assigned' MI plans for: #{other_consortia.join(', ')}"
    when 'Conflict'
      return conflict_text(mi_plan, mi_plans)
    else
      return nil
    end
  end

  def conflict_text(mi_plan, conflicting_mi_plans)
    mi_plans = conflicting_mi_plans.select{|plan| plan.id != mi_plan.id && plan.gene_id == mi_plan.gene_id}
    "Other MI plans for: #{mi_plans.map {|plan| plan.consortium.name}.join(', ')}" unless mi_plans.empty?
  end

  def report_csv_path
    uri = request.env['REQUEST_URI']
    if uri =~ /\?/
      uri + '&format=csv'
    else
      uri + '?format=csv'
    end
  end

  def boolean_to_text(bool)
    bool ? 'Yes' : 'No'
  end

  def pretty_mutation_type(mutation_type)
    case mutation_type
      when 'conditional_ready'
        'Knockout First'
      when 'deletion'
        'Deletion'
      when 'targeted_non_conditional'
        'Targeted Non Conditional'
    end
      
  end

  def allele_symbol_for_csv(symbol)
    symbol.to_s.gsub(/<sup>/, '<').gsub(/<\/sup>/, '>').html_safe
  end

  def report_csv_data(hash, consortium, column, date = nil)
    if date
      hash["#{consortium}-#{date}-#{column}"].to_i
    else
      hash["#{consortium}-#{column}"].to_i
    end
  end

  def report_link_to(hash, filter, type, options = {})
    options = {:type => type, :filter_by => :consortium}.merge(options)

    if options[:centre]
      value = hash["#{filter}-#{options[:centre]}-#{type}"].to_i
      options[:pcentre] = options[:centre] if options[:centre]
      options.delete(:centre)
    else
      value = hash["#{filter}-#{type}"].to_i
    end

    options[options[:filter_by]] = filter
    options.delete(:filter_by)

    if type =~ /Efficiency|Cumulative|Goal/i
      value
    elsif value > 0
      link_to(value, report_detail_path(options))
    end
  end

  def report_detail_path(options = {})
    path = SITE_PATH + '/v2/reports/mi_production/production_detail'
    path = path + '?' + options.to_query unless options.empty?
  
    path
  end

  def efficiency_percentage(hash, consortium, centre)
    total  = hash["#{consortium}-#{centre}-count"].to_f
    subset = hash["#{consortium}-#{centre}-gtc_count"].to_f

    if subset == 0 || total == 0
      0.0
    else
      ((subset / total) * 100.0).ceil
    end
  end

end