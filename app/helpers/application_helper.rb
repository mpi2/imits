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
    content_tag(:div, message.html_safe, args.merge(:class => ['message', message_type]))
  end

  def link_to_add_fields(name, f, association)
    @new_object = f.object.send(association).class.new
    id = @new_object.object_id
    fields = f.fields_for(association, @new_object, child_index: id) do |builder|
      render(association.to_s.singularize + "_fields", f: builder)
    end
    link_to(name, '#', class: "add_row", :"data-fields" => fields.gsub("\n", ""), :"data-object-id" => @new_object.object_id)
  end
end
