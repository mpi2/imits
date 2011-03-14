module ApplicationHelper
  def flash_message(message_type)
    if ! flash[message_type].blank?
      content_tag(:div, :class => ['flash', message_type]) do
        content_tag(:p, message_type.capitalize, :class => 'header') +
                content_tag(:p, flash[message_type], :class => 'body')
      end
    end
  end
end
