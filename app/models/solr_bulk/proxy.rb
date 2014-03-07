
module SolrBulk
  class NetHttpProxy
    def self.should_use_proxy_for?(host)
      ENV['NO_PROXY'].to_s.delete(' ').split(',').each do |no_proxy_host_part|
        if host.include?(no_proxy_host_part)
          return false
        end
      end

      return true
    end

    def initialize(solr_uri)
      if ENV['HTTP_PROXY'].present? and self.class.should_use_proxy_for?(solr_uri.host)
        proxy_uri = URI.parse(ENV['HTTP_PROXY'])
        @http = Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password)
      else
        @http = Net::HTTP
      end
    end

    def start(*args, &block)
      @http.start(*args, &block)
    end
  end

  class Proxy
    def initialize(uri)
      @solr_uri = URI.parse(uri)
      @http = NetHttpProxy.new(@solr_uri)
    end

    def search(solr_params)
      docs = nil
      uri = @solr_uri.dup
      uri.query = solr_params.merge(:wt => 'json', :rows => '100000').to_query
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
        raise SolrBulk::Error, "Error during update_json: #{http_response.message}\n#{http_response.body}\n\nRequest body:#{request.body}"
      end
    end

    protected :handle_http_response_error
  end
end
