class MiAttemptFieldGenerator < FieldGenerator

  def emma_status_field
    field_html = @form.select(:emma_status, MiAttempt::EMMA_OPTIONS.invert)
    form_field(:emma_status, 'EMMA Status', field_html)
  end

  def strains_field(name, options = {})
    label = options.has_key?(:label) ? options[:label] : nil
    name = name.to_s
    field_html = @form.collection_select(name+'_name', Strain.order(:name), :name, :pretty_drop_down, :include_blank => true)
    form_field(name+'_name', label, field_html)
  end

  def qc_fields
    qc_statuses = QcResult.all
    ColonyQc::QC_FIELDS.map {|qc_field| qc_field(qc_field, qc_statuses, :description, :description) }.join.html_safe
  end

  def privacy_field(options = {})
    label = options.has_key?(:label) ? options[:label] : nil
    field_html = @form.select(:privacy, MiAttempt::PRIVACY_OPTIONS)
    form_field(:privacy, label, field_html)
  end

  def crispr_allele_category_field(options = {})
    label = options.has_key?(:label) ? options[:label] : nil
    field_html = @form.select(:crispr_allele_category, Colony::CRISPR_ALLELE_CATEGORIES, { include_blank: true })
    form_field(:crispr_allele_category, label, field_html)
  end

  def qc_field(qc_field, collection, key, value, options = {})
    form_field("#{qc_field}_result", tidy_label(qc_field.to_s.gsub(/^qc_(.+)$/, '\1').titlecase),
      @form.collection_select("#{qc_field}_result", collection, key, value, options))
  end

end
