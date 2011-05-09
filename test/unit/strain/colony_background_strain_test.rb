require 'test_helper'

class Strain::ColonyBackgroundStrainTest < ActiveSupport::TestCase
  context 'Strain::ColonyBackgroundStrain' do
    should have_db_column(:id).with_options(:null => false)
    should have_db_index(:id).unique(true)
    should belong_to :strain

    should 'be populated with correct data' do
      assert_strain_types(Strain::ColonyBackgroundStrain, 'colony_background_strains')
    end

    should 'delegate name to Strain' do
      sid = Strain::ColonyBackgroundStrain.find(:first)
      assert_equal sid.name, sid.strain.name
    end
  end
end
