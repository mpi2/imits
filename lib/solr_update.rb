module SolrUpdate
end

require 'solr_update/error'
require 'solr_update/util'
require 'solr_update/config'
require 'solr_update/net_http_proxy'
require 'solr_update/index_proxy'
require 'solr_update/queue'
require 'solr_update/command_factory'
require 'solr_update/test_help'

SolrUpdate::Config.init_config