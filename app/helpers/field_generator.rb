class FieldGenerator
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormOptionsHelper

  def initialize(form)
    @form = form
  end

  def text_field(name, options = {})
    label = options.delete(:label)
    form_field(name, label, @form.text_field(name, options))
  end

  def number_field(name, options = {})
    raise 'Setting class not supported' if options[:class]
    text_field(name, options.merge(:class => 'number-field'))
  end

  def form_field(name, label, field_html, no_label = false)
    element_classes = []
    label ||= tidy_label(name.to_s.titlecase)
    if no_label
      contents = field_html
    else
      contents = @form.label(name, label) + "\n".html_safe + field_html
    end
    if ! @form.object.errors[name].blank?
      contents += "\n".html_safe + content_tag(:span, @form.object.errors[name].join(', '), :class => 'error-message')
      element_classes << 'errors'
    end
    return content_tag(:div, contents.html_safe, :class => element_classes.join(' ')).html_safe
  end

  def mouse_allele_type_field
    field_html = @form.select(:mouse_allele_type, ApplicationModel::MOUSE_ALLELE_OPTIONS.invert)
    form_field(:mouse_allele_type, nil, field_html)
  end

  def completion_note_type_field
    field_html = @form.select(:completion_note, ApplicationModel::COMPLETION_NOTE.invert)
    form_field(:completion_note, nil, field_html)
  end

  def priorities_field
    name = name.to_s
    field_html = @form.collection_select(:priority_name, EsCellQc::Priority.all, :name, :name, :include_blank => true)
    form_field(:priority_name, nil, field_html)
  end

  def drop_down_field(params)
    model = params[:model]
    field = params[:field]
    label = params[:label]
    no_lable = params[:no_label] || false
    name = name.to_s
    options = model.constantize.all
    field_html = @form.collection_select(field, options, :name, :name, :include_blank => true)
    form_field(field, label, field_html, no_lable)
  end


  private

  def tidy_label(old_label)
    new_label = [
      'glt',
      'cct',
      'het',
      'lr',
      'pcr',
      'sr',
      'qpcr',
      'loa',
      'tv'
    ].inject(old_label) do |label, snippet|
      label.gsub(/\b#{snippet}\b/i, snippet.upcase)
    end

    return new_label.
            gsub(/loxp/i, 'LoxP').
            gsub(/lacz/i, 'LacZ')

    return new_label
  end

end
