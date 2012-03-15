class MiAttemptFieldGenerator < FieldGenerator

  def emma_status_field
    field_html = @form.select(:emma_status, MiAttempt::EMMA_OPTIONS.invert)
    form_field(:emma_status, 'EMMA Status', field_html)
  end

  def strains_field(name)
    name = name.to_s
    strain_class = Strain.const_get(name.gsub(/_id$/, '').camelize)
    field_html = @form.collection_select(name+'_name', strain_class.all, :name, :name, :include_blank => true)
    form_field(name+'_name', nil, field_html)
  end

  def qc_fields
    qc_statuses =  QcResult.all
    MiAttempt::QC_FIELDS.map do |qc_field|
      form_field("#{qc_field}_result", tidy_label(qc_field.to_s.gsub(/^qc_(.+)$/, '\1').titlecase),
          @form.collection_select("#{qc_field}_result", qc_statuses, :description, :description))
    end.join.html_safe
  end

end
