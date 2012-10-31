class NetworkGraph::GeneNode < NetworkGraph::Node
  def initialize(gene, params)
    params[:rank] = 'source'
    super(gene, params)
    @marker_symbol = gene.marker_symbol.to_s
  end

  def label_html
    html = "<<table>" +
             "<tr><td colspan=\"2\">Gene</td></tr>" +
             "<tr><td>Marker Symbol:</td><td>#{CGI.escapeHTML(@marker_symbol)}</td></tr>" +
           "</table>>"
    return html
  end
end
