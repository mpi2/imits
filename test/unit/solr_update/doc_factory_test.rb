require 'test_helper'

class SolrUpdate::DocFactoryTest < ActiveSupport::TestCase
  context 'SolrUpdate::DocFactory' do

    context 'when creating solr docs for mi_attempt' do

      setup do
        @es_cell = Factory.create :es_cell,
                :gene => cbx1,
                :mutation_subtype => 'conditional_ready'
        @mi_attempt = Factory.create :mi_attempt, :id => 43,
                :colony_background_strain => Strain.first,
                :es_cell => @es_cell

        @doc = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt)
      end

      should 'set id and type' do
        assert_equal ['mi_attempt', 43], @doc.values_at('type', 'id')
      end

      should 'set mgi_accession_id' do
        assert_equal cbx1.mgi_accession_id, @doc['mgi_accession_id']
      end

      should 'set allele_type' do
        @es_cell.mutation_subtype = 'conditional_ready'
        doc = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt)
        assert_equal 'Conditional Ready', doc['allele_type']

        @es_cell.mutation_subtype = 'deletion'
        doc = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt)
        assert_equal 'Deletion', doc['allele_type']

        flunk "IT'S MORE COMPLICATED THAN THAT!"
      end

      should 'set strain of origin' do
        @mi_attempt.colony_background_strain = Strain.create!(:name => 'TEST STRAIN')
        doc = SolrUpdate::DocFactory.create_for_mi_attempt @mi_attempt
        assert_equal 'TEST STRAIN', doc['strain']
      end

      should 'set mgi_allele_name' do
        @mi_attempt.expects(:allele_symbol).returns('TEST ALLELE SYMBOL')
        doc = SolrUpdate::DocFactory.create_for_mi_attempt @mi_attempt
        assert_equal 'TEST ALLELE SYMBOL', doc['allele_name']
      end

    end

  end
end
