class NetworkGraph::MouseAlleleModNode < NetworkGraph::NodeWithStates

  def initialize(mouse_allele_mod, params)
    params[:rank] = "5"
    super(mouse_allele_mod, params)
    find_statuses(mouse_allele_mod)
    @colony_background_strain = mouse_allele_mod.colony.background_strain.try(:name).to_s
    @deleter_strain = mouse_allele_mod.deleter_strain.try(:name).to_s
    @colony_name = mouse_allele_mod.colony_name.to_s
    @allele_name = mouse_allele_mod.colony.try(:allele_symbol).to_s
  end

  def label_html
    html = "<<table>" +
             "<tr><td colspan=\"2\" border=\"0\">Mouse Allele Modification</td></tr>" +
             "<tr><td>Consortium:</td><td>#{CGI.escapeHTML(@consortium)}</td></tr>" +
             "<tr><td>Centre:</td><td>#{CGI.escapeHTML(@centre)}</td></tr>" +
             "<tr><td colspan=\"2\" border=\"0\"></td></tr>" +
             "<tr><td border=\"0\">Colony Details</td><td border=\"0\"></td></tr>" +
             "<tr><td>Colony name:</td><td>#{CGI.escapeHTML(@colony_name)}</td></tr>" +
             "<tr><td>Allele name:</td><td>#{CGI.escapeHTML(@allele_name)}</td></tr>" +
             "<tr><td>Colony background strain:</td><td>#{CGI.escapeHTML(@colony_background_strain)}</td></tr>" +
             "<tr><td>Deleter strain:</td><td>#{CGI.escapeHTML(@deleter_strain)}</td></tr>" +
             "<tr><td colspan=\"2\" border=\"0\"></td></tr>" +
             "<tr><td border=\"0\">Status Details</td><td border=\"0\"></td></tr>" +
             "<tr><td>Current Status:</td><td>#{CGI.escapeHTML(@current_status)}</td></tr>"
    ['Rederivation Started' , 'Rederivation Complete', 'Cre Excision Started', 'Cre Excision Complete'].each do |status|
      if @statuses.has_key?(status)
        html << "<tr><td>#{CGI.escapeHTML(status)}:</td><td>#{CGI.escapeHTML(@statuses[status])}</td></tr>"
      end
    end
    html << "</table>>"
    return html
  end
end
