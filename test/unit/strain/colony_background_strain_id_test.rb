require 'test_helper'

class Strain::ColonyBackgroundStrainIdTest < ActiveSupport::TestCase
  context 'Strain::ColonyBackgroundStrainId' do
    should have_db_column(:id).with_options(:null => false)
    should have_db_index(:id).unique(true)
    should belong_to :strain

    should 'be populated with correct data' do
      assert_strain_types(Strain::ColonyBackgroundStrainId, 'colony_background_strains')
    end
  end
end
