MiAttempt.class_eval do

  before_save :save_qc_fields

  validates_each :qc do |record, attr, value|
    acceptable_results = QcResult.all.map(&:description)
    error_messages = []
    record.qc.each_pair do |short_qc_field, result|
      next unless result

      unless acceptable_results.include? result
        error_messages << "#{short_qc_field} => '#{result}'"
      end
    end

    unless error_messages.blank?
      record.errors[:qc] = "Erroneous QC fields: #{error_messages.join ', '}"
    end
  end

  def qc
    if @qc.blank?
      @qc = {}

      QC_FIELDS.each do |qc_field|
        @qc[qc_field.to_s.gsub(/^qc_/, '')] = self.send(qc_field).try(:description)
      end
    end

    return @qc
  end

  def qc=(args)
    raise ArgumentError, "Expected hash, got #{args.class}" unless args.is_a? Hash
    args = args.stringify_keys
    self.qc.keys.each do |short_qc_field|
      if args.include? short_qc_field
        @qc[short_qc_field] = args[short_qc_field]
      end
    end
  end

  def save_qc_fields
    return if @qc.blank?

    @qc.each do |short_qc_field, result|
      next unless QC_FIELDS.include?( ('qc_' + short_qc_field).to_sym )
      result_model = QcResult.find_by_description(result)
      self.send "qc_#{short_qc_field}=", result_model
    end
  end
  protected :save_qc_fields

end
