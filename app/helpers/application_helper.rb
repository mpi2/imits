module ApplicationHelper
  def flash_message(message_type)
    if ! flash[message_type].blank?
      render_message(message_type, flash[message_type])
    end
  end

  def render_message(message_type, message = nil, args = {}, &block)
    if message.nil?
      message = capture(&block)
    end
    content_tag(:div, message, args.merge(:class => ['message', message_type]))
  end
end
