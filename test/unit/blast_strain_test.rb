require 'test_helper'

class BlastStrainTest < ActiveSupport::TestCase
  context 'BlastStrain' do
    should have_db_column(:id).with_options(:null => false)
    should belong_to :strain

    should 'be populated with correct data' do
      assert_strain_types(BlastStrain, 'blast_strains')
    end
  end
end
