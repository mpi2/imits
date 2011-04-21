require 'test_helper'

class ColonyBackgroundStrainTest < ActiveSupport::TestCase
  context 'ColonyBackgroundStrain' do
    should have_db_column(:id).with_options(:null => false)
    should have_db_index(:id).unique(true)
    should belong_to :strain

    should 'be populated with correct data' do
      assert_strain_types(ColonyBackgroundStrain, 'colony_background_strains')
    end
  end
end
