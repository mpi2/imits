module ReportsHelper

  def reason_for_inspect_or_conflict(table_type, string_array)

    text = case table_type
      when 'inspect-gtc'
        "GLT mouse produced at:"
      when 'inspect-mip'
        "MI already in progress at:"
      when 'inspect-con'
        "Other 'Assigned' MI plans for:"
      when 'conflict'
        "Other MI plans for:"
    end

    String.new.tap do |s|
      s << text
      s << " "
      s << string_array.to_s.gsub(/\{/, '').gsub(/\}/, '').gsub(/_/, ' ').gsub(',', ', ')
    end
  end

  def report_csv_path
    return '?format=csv' if request.env['REQUEST_URI'].blank?

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
    elsif options[:date]
      value = hash["#{filter}-#{options[:date]}-#{type}"].to_i
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

    if !options[:production_group].blank?
      case options[:production_group]
      when 'gene'
        options.delete(:production_group)
        gene_production_detail_path(options)
      when 'consortia'
        options.delete(:production_group)
        consortia_production_detail_path(options)
      else
        options.delete(:production_group)
        production_detail_path(options)
      end
    else
      production_detail_path(options)
    end
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

  def grid_qc_result(value, type = nil)
    return value if type =~ /colony_name|distribution_centre|es_cell/

    case value
      when /pass/, '3'
        'pass'
      when /fail|double|limit/, '2'
        'fail'
      else
        'na'
    end
  end

  ## Used in QcGridReport
  def grid_class(value, type)

    if ['insertion_score', 'threep_loxp_score', 'targeting_score', 'cassette_score'].include?(type)
      klass = "score score_#{value}"
    else
      klass = grid_qc_result(value)
    end

    if ['qc_three_prime_lr_pcr', 'chry'].include?(type)
      klass << ' right-border'
    end

    if type == 'chry'
      klass << ' spacing'
    end

    if QcGridReport.distribution_qc_columns.include?(type)
      klass << ' distribution_centre'
    end

    klass
  end

  def average_score(type, hash)
    if type == 'threep_loxp_score'
      total = hash['threep_loxp_score_total'].to_f
    else
      total = hash['count'].to_f
    end

    subset = hash[type].to_f

    (subset / total).round(1)
  end

end