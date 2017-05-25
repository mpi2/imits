class AlleleFieldGenerator < FieldGenerator
  
  def mouse_allele_type_field
  	allele = @form.object
    field_html = @form.select(:allele_type, Allele::ALLELE_OPTIONS.merge(Allele::CRISPR_ALLELE_OPTIONS).invert, include_blank: true)
    form_field(:allele_type, nil, field_html)
  end

  def mouse_allele_subtype_field
  	allele = @form.object
    field_html = @form.select(:allele_subtype, Allele::CRISPR_ALLELE_SUB_TYPE_OPTIONS, include_blank: true)
    form_field(:allele_subtype, nil, field_html)
  end

end
