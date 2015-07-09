class NetworkGraph::PhenotypingProductionNode < NetworkGraph::NodeWithStates

  def initialize(phenotyping_production, params)
    params[:rank] = "5"
    super(phenotyping_production, params)
    find_statuses(phenotyping_production)
    @colony_background_strain = phenotyping_production.colony_background_strain.try(:name).to_s
    @colony_name = phenotyping_production.colony_name.to_s
    @phenotyping_experiments_started = phenotyping_production.phenotyping_experiments_started.to_s
  end

  def label_html
    html = "<<table>" +
             "<tr><td colspan=\"2\" border=\"0\">Phenotyping</td></tr>" +
             "<tr><td>Consortium:</td><td>#{CGI.escapeHTML(@consortium)}</td></tr>" +
             "<tr><td>Centre:</td><td>#{CGI.escapeHTML(@centre)}</td></tr>" +
             "<tr><td colspan=\"2\" border=\"0\"></td></tr>" +
             "<tr><td border=\"0\">Phenotyping Details</td><td border=\"0\"></td></tr>" +
             "<tr><td>Colony name:</td><td>#{CGI.escapeHTML(@colony_name)}</td></tr>" +
             "<tr><td>Colony background strain:</td><td>#{CGI.escapeHTML(@colony_background_strain)}</td></tr>" +
             "<tr><td>Phenotyping Experiments Started:</td><td>#{CGI.escapeHTML(@phenotyping_experiments_started)}</td></tr>" +
             "<tr><td colspan=\"2\" border=\"0\"></td></tr>" +
             "<tr><td border=\"0\">Status Details</td><td border=\"0\"></td></tr>" +
             "<tr><td>Current Status:</td><td>#{CGI.escapeHTML(@current_status)}</td></tr>"
    ['Rederivation Started' , 'Rederivation Complete', 'Phenotyping Started', 'Phenotyping Complete'].each do |status|
      if @statuses.has_key?(status)
        html << "<tr><td>#{CGI.escapeHTML(status)}:</td><td>#{CGI.escapeHTML(@statuses[status])}</td></tr>"
      end
    end
    html << "</table>>"
    return html
  end
end
