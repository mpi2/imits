require 'test_helper'

class MiPlan::EsQcCommentTest < ActiveSupport::TestCase
  should validate_presence_of :name
  should validate_uniqueness_of :name
  should have_many :mi_plans

  should have_db_column(:name).with_options(:null => false)
  should have_db_index(:name).unique(true)

  should 'be seeded correctly' do
    comment = MiPlan::EsQcComment.find_by_name('No assay available')
    assert comment
  end
end
