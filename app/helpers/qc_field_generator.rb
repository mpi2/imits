class QcFieldGenerator < FieldGenerator
    
  def qc_field(qc_field)
    form_field("#{qc_field}", ProductionCentreQc::QC_FIELDS[qc_field][:name],
      @form.select("#{qc_field}", ProductionCentreQc::QC_FIELDS[qc_field][:values].map{|v| [v, v]}, {include_blank: true}, {disabled: true}))
  end

  def qc_field_text(qc_field)
    form_field("#{qc_field}", ProductionCentreQc::QC_FIELDS[qc_field][:name],
       @form.text_field(qc_field, {disabled: true}))
  end

end
