class NetworkGraph::MiAttemptNode < NetworkGraph::NodeWithStates

  def initialize(params)
    params[:rank] = "3"
    super(params)
    mi_attempt = MiAttempt.find_by_id(@id)
    find_statuses(mi_attempt)
    @colony_background_strain = params[:colony_background_strain]
    @test_cross_strain = params[:test_cross_strain]
    @colony_name = mi_attempt.colony_name
  end

  def label_html
    html = "<<table>" +
             "<tr><td colspan=\"2\">Mouse Production</td></tr>" +
             "<tr><td>Consortium:</td><td>#{CGI.escapeHTML(@consortium)}</td></tr>" +
             "<tr><td>Current Status:</td><td>#{CGI.escapeHTML(@current_status)}</td></tr>" +
             "<tr><td>Centre:</td><td>#{CGI.escapeHTML(@centre)}</td></tr>"
    ['Micro-injection in progress', 'Chimeras obtained', 'Genotype confirmed', 'Micro-injection aborted'].each do |status|
      if @statuses.has_key?(status)
        html << "<tr><td>#{CGI.escapeHTML(status)}:</td><td>#{CGI.escapeHTML(@statuses[status])}</td></tr>"
      end
    end
    html << "<tr><td>Colony background strain:</td><td>#{CGI.escapeHTML(@colony_background_strain)}</td></tr>"
    html << "<tr><td>Colony name:</td><td>#{CGI.escapeHTML(@colony_name)}</td></tr>"
    html << "<tr><td>Test cross strain:</td><td>#{CGI.escapeHTML(@test_cross_strain)}</td></tr>"
    html << "</table>>"
    return html
  end
end
