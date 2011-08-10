module ApplicationHelper
  def flash_message(message_type)
    if ! flash[message_type].blank?
      render_message(message_type, flash[message_type])
    end
  end

  def render_message(message_type, message)
    content_tag(:div, message, :class => ['message', message_type])
  end

  def extjs_tags
    html = stylesheet_link_tag('/extjs/resources/css/ext-all') + "\n"

    if Rails.env.production? or Rails.env.staging?
      html += javascript_include_tag('/extjs/ext-all')
    else
      html += javascript_include_tag('/extjs/ext-all-debug')
    end

    return html.html_safe
  end

  # TODO Come up with a better solution than this
  def javascript_include_imits_classes
    files = Dir.chdir(Rails.root + 'public/javascripts') { Dir.glob('Imits/**/*.js') }
    javascript_include_tag(*files, :cache => 'imits_all')
  end

end
