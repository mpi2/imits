require 'test_helper'

class Public::SolrUpdate::Queue::ItemTest < ActiveSupport::TestCase
  class MockError < RuntimeError; end

  def default_item
    @@default_item ||= Factory.create(:solr_update_queue_item_mi_attempt, :mi_attempt_id => 2).to_public
  end

  context 'Public::SolrUpdate::Queue::Item' do

    should 'be a sub-class of SolrUpdate::Queue::Item' do
      assert_include Public::SolrUpdate::Queue::Item.ancestors, SolrUpdate::Queue::Item
    end

    should 'limit the public mass-assignment API' do
      expected = []

      got = Public::SolrUpdate::Queue::Item.accessible_attributes.to_a
      assert_equal expected.sort, got.sort, "Unexpected: #{got - expected}; Not got: #{expected - got}"
    end

    should 'have defined attributes in serialized output' do
      expected = %w{
        id
        reference
        action
        created_at
      }
      got = default_item.as_json.keys
      assert_equal expected.sort, got.sort, "Unexpected: #{got - expected}; Not got: #{expected - got}"
    end

  end
end
