module ApplicationHelper
  def flash_message(message_type)
    if ! flash[message_type].blank?
      content_tag(:div, :class => ['flash', message_type]) do
        content_tag :p, flash[message_type]
      end
    end
  end
end
