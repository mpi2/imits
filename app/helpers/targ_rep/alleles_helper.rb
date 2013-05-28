module TargRep::AllelesHelper

  # Following helpers come from:
  # http://railsforum.com/viewtopic.php?id=28447

  # Add a new es cell form
  def add_es_cell_link(form_builder)

    onclick = String.new.tap do |page|
      form_builder.fields_for :es_cells, TargRep::EsCell.new, :child_index => 'NEW_RECORD' do |f|
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

end
