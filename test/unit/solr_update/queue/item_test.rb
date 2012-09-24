require 'test_helper'

class SolrUpdate::Queue::ItemTest < ActiveSupport::TestCase
  context 'SolrUpdate::Queue::Item' do

    should belong_to :mi_attempt
    should belong_to :phenotype_attempt

    should have_db_index(:mi_attempt_id).unique(true)
    should have_db_index(:phenotype_attempt_id).unique(true)

    should 'only ensure either an mi_attempt_id or a phenotype_attempt_id' do
      assert_raise(ActiveRecord::StatementInvalid) { SolrUpdate::Queue::Item.create! }
      assert_raise(ActiveRecord::StatementInvalid) { SolrUpdate::Queue::Item.create!(:mi_attempt_id => 2, :phenotype_attempt_id => 2) }
    end

  end
end
