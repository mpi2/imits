require 'test_helper'

class StrainTest < ActiveSupport::TestCase
  context 'Strain' do
    setup do
      Strain.create!(:name => 'Fred')
    end

    should have_db_column(:name).with_options(:null => false)
    should have_db_index(:name).unique(true)
    should validate_presence_of :name
    should validate_uniqueness_of :name
  end
end
