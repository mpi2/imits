module ApplicationHelper
  def flash_message(message_type)
    if ! flash[message_type].blank?
      render_message(message_type, flash[message_type])
    end
  end

  def render_message(message_type, message)
    content_tag(:div, :class => ['message', message_type]) do
      content_tag(:p, message_type.capitalize, :class => 'header') +
              content_tag(:p, message, :class => 'body')
    end
  end

  def mainnav_links
    retval = [
      ['Search & Edit', mi_attempts_path],
      ['Create', new_mi_attempt_path]
    ].map do |link|
      if @tab == link[0]
        link << {:class => 'current'}
      end
      link_to *link
    end
    return retval.join.html_safe
  end
end
