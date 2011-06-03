class MiAttemptFieldGenerator
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormOptionsHelper

  def initialize(form)
    @form = form
  end

  def emma_status_field
    field_html = @form.select(:emma_status, MiAttempt::EMMA_OPTIONS.invert)
    form_field(:emma_status, 'EMMA Status', field_html)
  end

  def text_field(name, options = {})
    label = options.delete(:label)
    form_field(name, label, @form.text_field(name, options))
  end

  def number_field(name, options = {})
    raise 'Setting class not supported' if options[:class]
    text_field(name, options.merge(:class => 'number-field'))
  end

  def strains_field(name)
    name = name.to_s
    strain_class = Strain.const_get(name.gsub(/_id$/, '').camelize)
    field_html = @form.collection_select(name+'_id', strain_class.all, :id, :name, :include_blank => true)
    form_field(name+'_id', nil, field_html)
  end

  def mouse_allele_type_field
    field_html = @form.select(:mouse_allele_type, MiAttempt::MOUSE_ALLELE_OPTIONS.map {|x, y| [y, x]})
    form_field(:mouse_allele_type, nil, field_html)
  end

  def qc_fields
    qc_statuses =  QcStatus.all
    MiAttempt::QC_FIELDS.map do |qc_field|
      form_field("#{qc_field}_id", tidy_label(qc_field.to_s.gsub(/^qc_(.+)$/, '\1').humanize),
          @form.collection_select("#{qc_field}_id", qc_statuses, :id, :description))
    end.join.html_safe
  end

  private

  def form_field(name, label, field_html)
    label ||= tidy_label(name.to_s.humanize)

    content_tag(:div,
      @form.label(name, label) + "\n" + field_html
    )
  end

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
