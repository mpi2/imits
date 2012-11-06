require 'test_helper'

class SolrUpdate::Queue::ItemTest < ActiveSupport::TestCase
  class MockError < RuntimeError; end

  context 'SolrUpdate::Queue::Item' do

    should belong_to :mi_attempt
    should belong_to :phenotype_attempt
    should belong_to :allele

    should have_db_index(:mi_attempt_id).unique(true)
    should have_db_index(:phenotype_attempt_id).unique(true)
    should have_db_index(:allele_id).unique(true)

    should 'only ensure either an mi_attempt_id or a phenotype_attempt_id or an allele_id' do
      assert_raise(ActiveRecord::StatementInvalid) { SolrUpdate::Queue::Item.create! }
      assert_raise(ActiveRecord::StatementInvalid) { SolrUpdate::Queue::Item.create!(:mi_attempt_id => 2, :phenotype_attempt_id => 2) }
      assert_raise(ActiveRecord::StatementInvalid) { SolrUpdate::Queue::Item.create!(:mi_attempt_id => 2, :phenotype_attempt_id => 2, :allele_id => 2) }
    end

    should 'have #reference' do
      i = SolrUpdate::Queue::Item.new(:mi_attempt_id => 5)
      assert_equal({'type' => 'mi_attempt', 'id' => 5}, i.reference)
      i = SolrUpdate::Queue::Item.new(:phenotype_attempt_id => 7)
      assert_equal({'type' => 'phenotype_attempt', 'id' => 7}, i.reference)
      i = SolrUpdate::Queue::Item.new(:allele_id => 9)
      assert_equal({'type' => 'allele', 'id' => 9}, i.reference)
    end

    should 'have valid action' do
      i = SolrUpdate::Queue::Item.create!(:mi_attempt_id => 1, :action => 'update'); i.reload
      assert_equal 'update', i.action
      i.update_attributes!(:action => 'delete'); i.reload
      assert_equal 'delete', i.action
      assert_raise(ActiveRecord::StatementInvalid) {i.update_attributes!(:action => 'nonsense')}
    end

    should '#add mi_attempts and #phenotype_attempts and alleles passed in as a hash of info to the DB' do
      SolrUpdate::Queue::Item.add({'type' => 'mi_attempt', 'id' => 2}, 'delete')
      SolrUpdate::Queue::Item.add({'type' => 'phenotype_attempt', 'id' => 3}, 'update')
      SolrUpdate::Queue::Item.add({'type' => 'allele', 'id' => 4}, 'update')

      assert_not_nil SolrUpdate::Queue::Item.find_by_mi_attempt_id_and_action(2, 'delete')
      assert_not_nil SolrUpdate::Queue::Item.find_by_phenotype_attempt_id_and_action(3, 'update')
      assert_not_nil SolrUpdate::Queue::Item.find_by_allele_id_and_action(4, 'update')
    end

    should 'allow #adding model objects directly instead of just the id' do
      mi = Factory.build :mi_attempt
      mi.stubs(:id => 5)
      pa = Factory.build :phenotype_attempt
      pa.stubs(:id => 8)

      a = Factory.build :allele
      a.stubs(:id => 12)

      SolrUpdate::Queue::Item.add(pa, 'delete')
      SolrUpdate::Queue::Item.add(mi, 'update')
      SolrUpdate::Queue::Item.add(a, 'update')

      assert_not_nil SolrUpdate::Queue::Item.find_by_mi_attempt_id_and_action(5, 'update')
      assert_not_nil SolrUpdate::Queue::Item.find_by_phenotype_attempt_id_and_action(8, 'delete')
      assert_not_nil SolrUpdate::Queue::Item.find_by_allele_id_and_action(12, 'update')
    end

    def setup_for_process
      @item2 = SolrUpdate::Queue::Item.create!(:mi_attempt_id => 1, :action => 'update', :created_at => '2012-01-02 00:00:00 UTC')
      @item1 = SolrUpdate::Queue::Item.create!(:phenotype_attempt_id => 2, :action => 'delete', :created_at => '2012-01-01 00:00:00 UTC')
      @item3 = SolrUpdate::Queue::Item.create!(:allele_id => 3, :action => 'update', :created_at => '2011-12-31 00:00:00 UTC')
    end

    should 'process items in order they were added: #process_in_order' do
      setup_for_process
      things_processed = []
      SolrUpdate::Queue::Item.process_in_order do |item|
        things_processed << [item.reference, item.action]
      end

      expected = [
        [{'type' => 'allele', 'id' => 3}, 'update'],
        [{'type' => 'phenotype_attempt', 'id' => 2}, 'delete'],
        [{'type' => 'mi_attempt', 'id' => 1}, 'update']
      ]

      assert_equal expected, things_processed

      assert_not_nil SolrUpdate::Queue::Item.find_by_id(@item1.id)
      assert_not_nil SolrUpdate::Queue::Item.find_by_id(@item2.id)
      assert_not_nil SolrUpdate::Queue::Item.find_by_id(@item3.id)
    end

    should 'only process a limited number of items per call if told to' do
      (1..10).each do |i|
        SolrUpdate::Queue::Item.create!(:action => 'update', :mi_attempt_id => i)
      end

      ids_processed = []

      SolrUpdate::Queue::Item.process_in_order(:limit => 3) do |item|
        ids_processed.push item.id
        item.destroy
      end

      assert_equal 3, ids_processed.size

      SolrUpdate::Queue::Item.process_in_order(:limit => 2) do |item|
        ids_processed.push item.id
        item.destroy
      end

      assert_equal 5, ids_processed.size

      SolrUpdate::Queue::Item.process_in_order do |item|
        ids_processed.push item.id
        item.destroy
      end

      assert_equal 10, ids_processed.size
    end

    should 'add only one command per item, removing any that are already present' do
      setup_for_process
      SolrUpdate::Queue::Item.add({'type' => 'mi_attempt', 'id' => 1}, 'delete')
      assert_nil SolrUpdate::Queue::Item.find_by_id(@item2.id)
      assert_not_nil SolrUpdate::Queue::Item.find_by_mi_attempt_id_and_action(1, 'delete')
    end

  end
end
