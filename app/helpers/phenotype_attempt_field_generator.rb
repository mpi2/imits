class PhenotypeAttemptFieldGenerator < FieldGenerator

  def qc_fields
    qc_statuses = QcResult.all
    PhenotypeAttempt::QC_FIELDS.map {|qc_field| qc_field(qc_field, qc_statuses, :description, :description) }.join.html_safe
  end

  def qc_field(qc_field, collection, key, value, options = {})
    form_field("#{qc_field}_result", tidy_label(qc_field.to_s.gsub(/^qc_(.+)$/, '\1').titlecase),
      @form.collection_select("#{qc_field}_result", collection, key, value, options))
  end

end
