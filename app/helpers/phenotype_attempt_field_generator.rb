class PhenotypeAttemptFieldGenerator < FieldGenerator

  def qc_fields
    qc_statuses = QcResult.all
    PhenotypeAttempt::QC_FIELDS.map {|qc_field| qc_field(qc_field, qc_statuses, :description, :description) }.join.html_safe
  end

  def qc_field(qc_field, collection, key, value, options = {})
    form_field("#{qc_field}_result", tidy_label(qc_field.to_s.gsub(/^qc_(.+)$/, '\1').titlecase),
      @form.collection_select("#{qc_field}_result", collection, key, value, options))
  end

  def strains_field(name)
    name = name.to_s
    field_html = @form.collection_select(name+'_name', Strain.order(:name), :name, :pretty_drop_down, :include_blank => true)
    form_field(name+'_name', nil, field_html)
  end

  def deleter_strains_field(name)
    name = name.to_s
    field_html = @form.collection_select(name+'_name', DeleterStrain.order(:name), :name, :name, :include_blank => true)
    form_field(name+'_name', nil, field_html)
  end

end
