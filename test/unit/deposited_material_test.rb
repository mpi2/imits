require 'test_helper'

class DepositedMaterialTest < ActiveSupport::TestCase
  context 'DepositedMaterial' do

    context '#name' do
      should have_db_column(:name).with_options(:null => false)
      should validate_uniqueness_of :name
      should have_db_index(:name).unique(true)

      should 'exist' do
        m = DepositedMaterial.create! :name => 'Nonexistent'
        assert_equal 'Nonexistent', m.name
      end
    end

  end
end
