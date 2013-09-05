class AuditRevisionFormatter

attr_accessor :model

  def initialize(options)
    options.symbolize_keys!
    @model = options[:model]
    translations
    build_translations
  end

  def translations
    @translations ||= {}
  end

  def build_translations
    {
      'production_centre_id' => {klass: Centre},
      'consortium_id' => {klass: Consortium},
      'blast_strain_id' => {klass: Strain},
      'colony_background_strain_id' => {klass: Strain},
      'test_cross_strain_id' => {klass: Strain},
      'deleter_strain_id' => {klass: Strain},
      'gene_id' => {klass: Gene, attr: 'marker_symbol'},
      'es_cell_id' => {klass: TargRep::EsCell}
    }.each do |easy_fkey, opts|
      klass = opts[:klass]
      attr = opts[:attr] || :name

      translations[easy_fkey] = proc {|values| values.map {|i| klass.find_by_id(i).try(attr) } }
    end

    [
      'status_id',
      'priority_id',
      'sub_project_id',
      'es_cell_id'
    ].each do |fkey|
      klass_name = fkey.gsub(/_id$/, '').camelize
      translations[fkey] = proc do |values|
        values.map do |i|
          if ['EsCell', 'TargRep::EsCell'].include?(klass_name)
            klass_name = "TargRep::EsCell"
          elsif ['Status', 'Priority', 'SubProject'].include?(klass_name)
            klass_name = "#{model.to_s}::#{klass_name}"
            puts klass_name
          end

          Rails.logger.info klass_name

          klass_name.constantize.find_by_id(i).try(:name)
        end
      end
    end

  end


  def changed_values(h1, h2)
    retval = {}

    h2.each do |key, new_value|
      old_value = h1[key]

      if old_value != new_value
        retval[key] = new_value
      end
    end

    return retval
  end

  def pre_translate(hash)
    translated = {}
    hash.each do |key, value|
      if ['mi_attempt_status_id', 'mi_plan_status_id'].include?(key)
        translated['status_id'] = value
      elsif key == 'mi_plan_priority_id'
        translated['priority_id'] = value
      else
        translated[key] = value
      end
    end
    return translated
  end

  def translate(hash)
    translated = {}

    hash.each do |key, values|
      formatted_key = key.gsub(/_id$/, '')

      if ! values.kind_of? Array
        values = [nil, values]
      end

      next if values[0].blank? and values[1].blank?

      if translations.has_key?(key)
        translated[formatted_key] = translations[key].call(values)
      else
        translated[formatted_key] = values
      end
    end

    return translated
  end

  def get_formatted_changes(hash)
    return translate(pre_translate(hash))
  end

end
