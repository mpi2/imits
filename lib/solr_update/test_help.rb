module SolrUpdate::TestHelp

  def self.included(base)
    base.class_eval do
      cattr_accessor :test_solr_server_running

      extend ClassMethods

      begin
        Net::HTTP.get(URI.parse('http://localhost:8984/solr'))
        self.test_solr_server_running = true
      rescue SystemCallError
        STDERR.puts('ERRORERRORERRORERRORERRORERRORERRORERRORERRORERRORERRORERRORERRORERRORERROR',
          'No test mpi2_solr server found running, some tests will be disabled or fail!  Check out mpi2_solr and start with "./bin/start.sh -p 8984"')
        self.test_solr_server_running = false
      end
    end

  end

  module ClassMethods
    def should_if_solr(arg, &block)
      if test_solr_server_running
        should(arg, &block)
      else
        should_eventually(arg + ' ||DISABLED DUE TO NO mpi2_solr SERVER||')
      end
    end
  end

end
