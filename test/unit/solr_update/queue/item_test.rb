require 'test_helper'

class SolrUpdate::Queue::ItemTest < ActiveSupport::TestCase
  class MockError < RuntimeError; end

  context 'SolrUpdate::Queue::Item' do

    should belong_to :mi_attempt
    should belong_to :phenotype_attempt

    should have_db_index(:mi_attempt_id).unique(true)
    should have_db_index(:phenotype_attempt_id).unique(true)

    should 'only ensure either an mi_attempt_id or a phenotype_attempt_id' do
      assert_raise(ActiveRecord::StatementInvalid) { SolrUpdate::Queue::Item.create! }
      assert_raise(ActiveRecord::StatementInvalid) { SolrUpdate::Queue::Item.create!(:mi_attempt_id => 2, :phenotype_attempt_id => 2) }
    end

    should 'have valid command_type' do
      i = SolrUpdate::Queue::Item.create!(:mi_attempt_id => 1, :command_type => 'update'); i.reload
      assert_equal 'update', i.command_type
      i.update_attributes!(:command_type => 'delete'); i.reload
      assert_equal 'delete', i.command_type
      assert_raise(ActiveRecord::StatementInvalid) {i.update_attributes!(:command_type => 'nonsense')}
    end

    should '#add mi_attempts and #phenotype_attempts passed in as a hash of info to the DB' do
      SolrUpdate::Queue::Item.add({'type' => 'mi_attempt', 'id' => 2}, 'delete')
      SolrUpdate::Queue::Item.add({'type' => 'phenotype_attempt', 'id' => 3}, 'update')

      assert_not_nil SolrUpdate::Queue::Item.find_by_mi_attempt_id_and_command_type(2, 'delete')
      assert_not_nil SolrUpdate::Queue::Item.find_by_phenotype_attempt_id_and_command_type(3, 'update')
    end

    should 'allow #adding model objects directly instead of just the id' do
      mi = Factory.build :mi_attempt
      mi.stubs(:id => 5)
      pa = Factory.build :phenotype_attempt
      pa.stubs(:id => 8)

      SolrUpdate::Queue::Item.add(pa, 'delete')
      SolrUpdate::Queue::Item.add(mi, 'update')

      assert_not_nil SolrUpdate::Queue::Item.find_by_mi_attempt_id_and_command_type(5, 'update')
      assert_not_nil SolrUpdate::Queue::Item.find_by_phenotype_attempt_id_and_command_type(8, 'delete')
    end

    def setup_for_process
      @item2 = SolrUpdate::Queue::Item.create!(:mi_attempt_id => 1, :command_type => 'update', :created_at => '2012-01-02 00:00:00 UTC')
      @item1 = SolrUpdate::Queue::Item.create!(:phenotype_attempt_id => 2, :command_type => 'delete', :created_at => '2012-01-01 00:00:00 UTC')
    end

    should 'process mi_attempts in order they were added and deletes them: #process_in_order' do
      setup_for_process
      things_processed = []
      SolrUpdate::Queue::Item.process_in_order do |object_id, command_type|
        things_processed << [object_id, command_type]
      end

      expected = [
        [{'type' => 'phenotype_attempt', 'id' => 2}, 'delete'],
        [{'type' => 'mi_attempt', 'id' => 1}, 'update']
      ]

      assert_equal expected, things_processed

      assert_nil SolrUpdate::Queue::Item.find_by_id(@item1.id)
      assert_nil SolrUpdate::Queue::Item.find_by_id(@item2.id)
    end

    should 'not delete queue item if an exception is raised during processing' do
      setup_for_process
      assert_raise(MockError) do
        SolrUpdate::Queue::Item.process_in_order do |object_id, command_type|
          if object_id['type'] == 'mi_attempt'
            raise MockError
          end
        end
      end

      assert_nil SolrUpdate::Queue::Item.find_by_id(@item1.id)
      assert_not_nil SolrUpdate::Queue::Item.find_by_id(@item2.id)
    end

  end
end
