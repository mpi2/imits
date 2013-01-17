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
    @new_object = f.object.send(association).new
    id = @new_object.object_id
    fields = f.fields_for(association, @new_object, child_index: id) do |builder|
      render('/shared/' + association.to_s.singularize + "_fields", f: builder)
    end
    link_to(name, '#', class: "add-row", :"data-fields" => fields.gsub("\n", ""), :"data-object-id" => @new_object.object_id)
  end

  def grid_redirect_path(consortium_name, pc_name, distribution_network, dc_name)
    ammended_table_name = @table_name.gsub(/_distribution_centres/, "s_distribution_centres")
    send("grid_redirect_#{ammended_table_name}_path", {:consortium_name => consortium_name, :pc_name => pc_name, :distribution_network => distribution_network, :dc_name => dc_name})
  end
end
