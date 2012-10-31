class NetworkGraph::PhenotypeAttemptNode < NetworkGraph::NodeWithStates
  def initialize(params)
    params[:rank] = "4"
    super(params)
    @cre_deleter_strain = params[:cre_deleter_strain]
    find_statuses(PhenotypeAttempt.find_by_id(@id))
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
    html << "</table>>"
    return html
  end
end
