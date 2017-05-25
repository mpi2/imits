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
  
end
