class MiAttemptFieldGenerator
  include ActionView::Helpers::TagHelper

  def initialize(form)
    @form = form
  end

  def text_field(name, options = {})
    return form_field(name, @form.text_field(name, :class => options[:class]))
  end

  private

  def form_field(name, field_html)
    return content_tag(:div,
      @form.label(name) + "\n" + field_html
    )
  end
end
