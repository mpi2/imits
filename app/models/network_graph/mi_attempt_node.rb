class NetworkGraph::MiAttemptNode < NetworkGraph::NodeWithStates

  def initialize(mi_attempt, params)
    params[:rank] = "3"
    super(mi_attempt, params)
    find_statuses(mi_attempt)
    @es_cell_mf_ref = mi_attempt.es_cell.blank? ? mi_attempt.mutagenesis_factor.external_ref : mi_attempt.es_cell.name
    @predicted_allele = mi_attempt.es_cell.blank? ? '' : mi_attempt.es_cell.alleles[0].try(:allele_symbol)
    @blast_strain = mi_attempt.blast_strain.try(:name).to_s
    @test_cross_strain = mi_attempt.test_cross_strain.try(:name).to_s
    @external_ref = mi_attempt.external_ref.to_s
  end

  def label_html
    html = "<<table>" +
             "<tr><td colspan=\"2\" border=\"0\">Micro Injection</td></tr>" +
             "<tr><td>Consortium:</td><td>#{CGI.escapeHTML(@consortium)}</td></tr>" +
             "<tr><td>Centre:</td><td>#{CGI.escapeHTML(@centre)}</td></tr>" +
             "<tr><td colspan=\"2\" border=\"0\"></td></tr>" +
             "<tr><td border=\"0\">Micro Injection Details</td><td border=\"0\"></td></tr>" +
             "<tr><td>Ref:</td><td>#{CGI.escapeHTML(@external_ref)}</td></tr>" +
             "<tr><td>ES Cell / Mutagenesis Factor Ref:</td><td>#{CGI.escapeHTML(@es_cell_mf_ref)}</td></tr>" +
             "<tr><td>Predicted Allele:</td><td>#{CGI.escapeHTML(@predicted_allele)}</td></tr>" +
             "<tr><td colspan=\"2\" border=\"0\"></td></tr>" +
             "<tr><td border=\"0\">Strain Details</td><td border=\"0\"></td></tr>" +
             "<tr><td>Blast strain:</td><td>#{CGI.escapeHTML(@blast_strain)}</td></tr>" +
             "<tr><td>Test Cross strain:</td><td>#{CGI.escapeHTML(@test_cross_strain)}</td></tr>" +
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
