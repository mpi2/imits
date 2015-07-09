class NetworkGraph::MiAttemptNode < NetworkGraph::NodeWithStates

  def initialize(mi_attempt, params)
    params[:rank] = "3"
    super(mi_attempt, params)
    find_statuses(mi_attempt)
    @colony_background_strain = mi_attempt.colony_background_strain.try(:name).to_s
    @test_cross_strain = mi_attempt.test_cross_strain.try(:name).to_s
    @colony_name = mi_attempt.colony_name.to_s
    @allele_name = mi_attempt.colony.try(:allele_symbol).to_s
  end

  def label_html
    html = "<<table>" +
             "<tr><td colspan=\"2\" border=\"0\">Micro Injection</td></tr>" +
             "<tr><td>Consortium:</td><td>#{CGI.escapeHTML(@consortium)}</td></tr>" +
             "<tr><td>Centre:</td><td>#{CGI.escapeHTML(@centre)}</td></tr>" +
             "<tr><td colspan=\"2\" border=\"0\"></td></tr>" +
             "<tr><td border=\"0\">Colony Details</td><td border=\"0\"></td></tr>" +
             "<tr><td>Colony name:</td><td>#{CGI.escapeHTML(@colony_name)}</td></tr>" +
             "<tr><td>Allele name:</td><td>#{CGI.escapeHTML(@allele_name)}</td></tr>" +
             "<tr><td>Colony background strain:</td><td>#{CGI.escapeHTML(@colony_background_strain)}</td></tr>" +
             "<tr><td>Test cross strain:</td><td>#{CGI.escapeHTML(@test_cross_strain)}</td></tr>" +
             "<tr><td colspan=\"2\" border=\"0\"></td></tr>" +
             "<tr><td border=\"0\">Status Details</td><td border=\"0\"></td></tr>" +
             "<tr><td>Current Status:</td><td>#{CGI.escapeHTML(@current_status)}</td></tr>"
    ['Micro-injection in progress', 'Chimeras obtained', 'Founder obtained', 'Genotype confirmed', 'Micro-injection aborted'].each do |status|
      if @statuses.has_key?(status)
        html << "<tr><td>#{CGI.escapeHTML(status)}:</td><td>#{CGI.escapeHTML(@statuses[status])}</td></tr>"
      end
    end
    html << "</table>>"
    return html
  end
end
