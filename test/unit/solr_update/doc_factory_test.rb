require 'test_helper'

class SolrUpdate::DocFactoryTest < ActiveSupport::TestCase
  context 'SolrUpdate::DocFactory' do

    context 'when creating solr docs for mi_attempt' do
      should 'set id and type' do
        @mi_attempt = Factory.build :mi_attempt
        @mi_attempt.stubs(:id => 43)

        @doc = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt)
        assert_equal ['mi_attempt', 43], @doc.values_at('type', 'id')
      end
    end

  end
end
