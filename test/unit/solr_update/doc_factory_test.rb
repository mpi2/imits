require 'test_helper'

class SolrUpdate::DocFactoryTest < ActiveSupport::TestCase
  context 'SolrUpdate::DocFactory' do

    context 'when creating solr docs for mi_attempt' do
      def setup_mi_attempt_and_doc
        @mi_attempt = Factory.create :mi_attempt, :id => 43,
                :es_cell => Factory.create(:es_cell, :gene => cbx1)

        @doc = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt)
      end

      should 'set id and type' do
        setup_mi_attempt_and_doc
        assert_equal ['mi_attempt', 43], @doc.values_at('type', 'id')
      end

      should 'set mgi_accession_id' do
        setup_mi_attempt_and_doc
        assert_equal cbx1.mgi_accession_id, @doc['mgi_accession_id']
      end

      should 'set allele_type based' do
        flunk
      end
    end

  end
end
