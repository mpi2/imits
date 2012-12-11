module SolrUpdate::IndexProxy
  def self.get_uri_for(name)
    return URI.parse(SolrUpdate::Config.fetch('index_proxy').fetch(name))
  end

  class Base

    def self.get_uri
      SolrUpdate::IndexProxy.get_uri_for(index_name)
    end

    def initialize
      @solr_uri = self.class.get_uri.freeze
      @http = SolrUpdate::NetHttpProxy.new(@solr_uri)
    end

    def search(solr_params)
      docs = nil
      uri = @solr_uri.dup
      uri.query = solr_params.merge(:wt => 'json').to_query
      uri.path = uri.path + '/select'

      @http.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri.request_uri
        http_response = http.request(request)
        handle_http_response_error(http_response)

        response_body = JSON.parse(http_response.body)
        docs = response_body.fetch('response').fetch('docs')
      end
      return docs
    end

    def update(commands_packet)
      uri = @solr_uri.dup
      uri.path = uri.path + '/update/json'
      @http.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Post.new uri.request_uri
        request.content_type = 'application/json'
        request.body = commands_packet
        http_response = http.request(request)
        handle_http_response_error(http_response, request)
      end
    end

    def handle_http_response_error(http_response, request = nil)
      if ! http_response.kind_of? Net::HTTPSuccess
        raise SolrUpdate::UpdateError, "Error during update_json: #{http_response.message}\n#{http_response.body}\n\nRequest body:#{request.body}"
      end
   end
    protected :handle_http_response_error
  end

  class Gene < Base
    def self.index_name; 'gene'; end

    def get_marker_symbol(mgi_accession_id)
      docs = search(:q => "mgi_accession_id:\"#{mgi_accession_id}\"")
      Rails.logger.debug("GENELOOKUP: Index lookup being performed on mgi_accession_id:\"#{mgi_accession_id}\"")
      if ! docs.first
        raise SolrUpdate::LookupError, "Could not look up marker symbol for mgi_accession_id:\"#{mgi_accession_id}\""
      end
      return docs.first.fetch('marker_symbol')
    end

    private :update
  end

  class Allele < Base
    def self.index_name; 'allele'; end
  end

end
