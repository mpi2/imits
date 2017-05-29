class PhenotypeAttemptFieldGenerator < FieldGenerator

  def strains_field(name)
    name = name.to_s
    field_html = @form.collection_select(name+'_name', Strain.where("name != '(B6;129-Gt(ROSA)26Sor<tm1(DTA)Mrc>/J x B6.FVB-Tg(Ddx4-cre)1Dcas>/J)F1/MvwJ'").order(:name), :name, :pretty_drop_down, :include_blank => true)
    form_field(name+'_name', nil, field_html)
  end

  def strains_field_no_label(name)
    element_classes = []
    name = name.to_s
    field_html = @form.collection_select(name+'_name', Strain.where("name != '(B6;129-Gt(ROSA)26Sor<tm1(DTA)Mrc>/J x B6.FVB-Tg(Ddx4-cre)1Dcas>/J)F1/MvwJ'").order(:name), :name, :pretty_drop_down, :include_blank => true)

    return content_tag(:div, field_html.html_safe, :class => element_classes.join(' ')).html_safe
  end
  
  def deleter_strains_field(name)
    name = name.to_s
    field_html = @form.collection_select(name+'_name', DeleterStrain.order(:name), :name, :name, :include_blank => true)
    form_field(name+'_name', nil, field_html)
  end

  def qc_field(qc_field)
    form_field("qc_#{qc_field}_result", ProductionCentreQc::QC_FIELDS[qc_field][:name],
      @form.select("qc_#{qc_field}_result", ProductionCentreQc::QC_FIELDS[qc_field][:values].map{|v| [v, v]}, {include_blank: true}))
  end

end
