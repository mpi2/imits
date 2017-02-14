module TargRep::AllelesHelper

  # Following helpers come from:
  # http://railsforum.com/viewtopic.php?id=28447

  # Add a new es cell form
  def add_es_cell_link(form_builder)

    onclick = String.new.tap do |page|
      form_builder.fields_for :es_cells, :child_index => 'NEW_RECORD' do |f|
        html = render( :partial => 'es_cell_form', :locals => { :f => f } )

        page << "$('#es_cells').append('#{escape_javascript(html)}'.replace(/NEW_RECORD/g, new Date().getTime()));"
      end
    end

    link_to_function( 'Add an ES Cell',  onclick)
  end

  # Add a new targeting vector form
  def add_targ_vec_link(form_builder)
    onclick = String.new.tap do |page|
      form_builder.fields_for :targeting_vectors, TargRep::TargetingVector.new, :child_index => 'NEW_RECORD' do |f|
        html = render :partial => 'targ_vec_form', :locals => { :f => f }
        page << "$('#targeting_vectors').append('#{escape_javascript(html)}'.replace(/NEW_RECORD/g, new Date().getTime()));"
      end
    end
    link_to_function( 'Add a targeting vector', onclick)
  end

  def gene_trap?
    @klass == TargRep::GeneTrap
  end

  def link_to_add_fields(name, f, association, options = {})
    html_id = options[:id] || ""
    @new_object = f.object.send(association).new
    id = @new_object.object_id
    fields = f.fields_for(association, @new_object, child_index: id) do |builder|
      render('/shared/' + association.to_s.singularize + "_fields", f: builder)
    end
    link_to(name, '#', class: "add-row", :"data-fields" => fields.gsub("\n", ""), :"data-object-id" => @new_object.object_id, :"data-table-id" => association.to_s + '_table', :id => html_id)
  end
end
