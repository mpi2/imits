class NetworkGraph::ColonyNode < NetworkGraph::Node

  def initialize(colony, params)
    params[:rank] = "4"
    super(colony, params)
    @colony_background_strain = colony.background_strain.try(:name).to_s
    @colony_name = colony.name.to_s
    @glt = colony.genotype_confirmed ? 'Yes' : 'No'
    @allele_name = colony.try(:allele_symbol).to_s
    @dist_centre = colony.distribution_centres_formatted_display
  end

  def label_html
    html = "<<table>" +
             "<tr><td colspan=\"2\" border=\"0\">F1 Colony</td></tr>" +
             "<tr><td>Colony name:</td><td>#{CGI.escapeHTML(@colony_name)}</td></tr>" +
             "<tr><td>Genotype Confirmed:</td><td>#{CGI.escapeHTML(@glt)}</td></tr>" +             
             "<tr><td>Allele name:</td><td>#{CGI.escapeHTML(@allele_name)}</td></tr>" +
             "<tr><td>Colony background strain:</td><td>#{CGI.escapeHTML(@colony_background_strain)}</td></tr>" +
             "<tr><td colspan=\"2\" border=\"0\">Distribution Centres</td></tr>" +
             "<tr><td>Centre / Network:</td><td>#{CGI.escapeHTML(@dist_centre)}</td></tr>" +
           "</table>>"
    return html
  end
end
