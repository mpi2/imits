class SolrUpdate::Error < RuntimeError; end
class SolrUpdate::LookupError < SolrUpdate::Error; end
class SolrUpdate::UpdateError < SolrUpdate::Error; end
