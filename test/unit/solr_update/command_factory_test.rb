require 'test_helper'

class SolrUpdate::CommandFactoryTest < ActiveSupport::TestCase
  context 'SolrUpdate::CommandFactory' do

    setup do
      SolrUpdate::Observer::MiAttempt.stubs(:after_save)
      SolrUpdate::Observer::MiAttempt.stubs(:after_destroy)
      SolrUpdate::Observer::PhenotypeAttempt.stubs(:after_save)
      SolrUpdate::Observer::PhenotypeAttempt.stubs(:after_destroy)
    end

    context 'when creating solr command for an mi_attempt that was updated' do

      setup do
        @mi_attempt = Factory.create :mi_attempt, :id => 55
        SolrUpdate::DocFactory.expects(:create_for_mi_attempt).with(@mi_attempt).returns({'mock_solr_doc' => true})

        @commands_json = SolrUpdate::CommandFactory.create_solr_command_to_update_in_index('type' => 'mi_attempt', 'id' => 55)
        @commands = JSON.parse(@commands_json)
      end

      should 'delete, add and commit in that order' do
        assert_equal ['delete', 'add', 'commit'], @commands.keys
      end

      should 'delete all docs for that mi_attempt before adding any' do
        assert_equal({'query' => 'type:mi_attempt AND id:55'}, @commands['delete'])
      end

      should 'add a solr doc for the mi_attempt' do
        assert_equal([{'mock_solr_doc' => true}], @commands['add'])
      end

      should 'do a commit' do
        assert_equal({}, @commands['commit'])
      end
    end

  end
end
