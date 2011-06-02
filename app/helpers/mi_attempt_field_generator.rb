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

  def number_field(name)
    text_field(name, :class => 'number-field')
  end

  def qc_fields
    qc_statuses =  QcStatus.all
    MiAttempt::QC_FIELDS.map do |qc_field|
      form_field("#{qc_field}_id", qc_field.to_s.gsub(/^qc_(.+)$/, '\1').humanize,
          @form.collection_select("#{qc_field}_id", qc_statuses, :id, :description))
    end.join.html_safe
  end

  private

  def form_field(name, label, field_html)
    content_tag(:div,
      @form.label(name, label) + "\n" + field_html
    )
  end
end
