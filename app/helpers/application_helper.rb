module ApplicationHelper
  def flash_message(message_type)
    if ! flash[message_type].blank?
      render_message(message_type, flash[message_type])
    end
  end

  def render_message(message_type, message)
    content_tag(:div, message, :class => ['message', message_type])
  end
end
