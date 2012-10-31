class NetworkGraph::PhenotypeAttemptNode < NetworkGraph::NodeWithStates
  def initialize(phenotype_attempt, params)
    params[:rank] = "4"
    super(phenotype_attempt, params)
    @cre_deleter_strain = phenotype_attempt.deleter_strain.try(:name).to_s
    find_statuses(phenotype_attempt)
    @colony_name = phenotype_attempt.colony_name.to_s
  end

  def label_html
    html = "<<table>" +
             "<tr><td colspan=\"2\">Phenotype Attempt</td></tr>" +
             "<tr><td>Consortium:</td><td>#{CGI.escapeHTML(@consortium)}</td></tr>" +
             "<tr><td>Centre:</td><td>#{CGI.escapeHTML(@centre)}</td></tr>" +
             "<tr><td>Current Status:</td><td>#{CGI.escapeHTML(@current_status)}</td></tr>" +
             "<tr><td>Cre Deleter Strain:</td><td>#{CGI.escapeHTML(@cre_deleter_strain)}</td></tr>"
    ['Phenotype Attempt Registered', 'Rederivation Started', 'Rederivation Complete', 'Cre Excision Started', 'Cre Excision Complete','Phenotyping Started', 'Phenotyping Complete', 'Phenotype Attempt Aborted'].each do |status|
      if @statuses.has_key?(status)
        html << "<tr><td>#{CGI.escapeHTML(status)}:</td><td>#{CGI.escapeHTML(@statuses[status])}</td></tr>"
      end
    end
    html << "<tr><td>Colony name:</td><td>#{CGI.escapeHTML(@colony_name)}</td></tr>"
    html << "</table>>"
    return html
  end
end
