class SolrUpdate::NetHttpProxy
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
