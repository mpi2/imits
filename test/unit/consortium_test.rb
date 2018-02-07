require 'test_helper'

class ConsortiumTest < ActiveSupport::TestCase

  setup do
    Factory.create :consortium
  end

  context 'Consortium' do

    context 'database table' do
      should have_db_column(:id).of_type(:integer).with_options(:primary => true)
      should have_db_column(:name).of_type(:string).with_options(:null => false)
      should have_db_column(:funding).of_type(:string)
      should have_db_column(:participants).of_type(:text)
      should have_db_column(:contact).of_type(:string)
      should have_db_column(:created_at).of_type(:datetime)
      should have_db_column(:updated_at).of_type(:datetime)
      should have_db_column(:credit_centre_with_production).of_type(:boolean).with_options(:default => true)
    end

    context 'Associations and Validations' do
      should validate_presence_of :name
      should validate_uniqueness_of :name
      should have_many :mi_plans
      should have_many :production_goals
      should have_many :tracking_goals
    end

    should 'have groupings' do
      assert_kind_of(Array, Consortium.komp2)
      assert_equal Consortium.komp2.length, 3, "KOMP2 group has more than 3 entries"
      assert_equal Consortium.komp2, [Consortium['BaSH'], Consortium['DTCC'], Consortium['JAX']], 'KOMP2 group is not equal to BaSH, DTCC and JAX'

      assert_kind_of(Array, Consortium.impc)
      assert_equal Consortium.impc.length, 6, "IMPC group has more than 6 entries"
      assert_equal Consortium.impc, [Consortium['Helmholtz GMC'], Consortium['MGP'], Consortium['MRC'], Consortium['NorCOMM2'], Consortium['Phenomin'], Consortium['MARC']], 'IMPC group is not equal to Helmholtz GMC, MGP, MRC, NorCOMM2, Phenomin, MARC'

      assert_kind_of(Array, Consortium.legacy)
      assert_equal Consortium.legacy.length, 4, "IMPC group has more than 4 entries"
      assert_equal Consortium.legacy, [Consortium['DTCC-Legacy'], Consortium['EUCOMM-EUMODIC'], Consortium['MGP Legacy'], Consortium['UCD-KOMP']], 'IMPC group is not equal to DTCC-Legacy, EUCOMM-EUMODIC, MGP Legacy, UCD-KOMP'

      assert_equal Consortium['BaSH'].consortia_group_and_order, ['KOMP2', 1], 'BaSH belongs to KOMP2 group and has order 1'
      assert_equal Consortium['Helmholtz GMC'].consortia_group_and_order, ['IMPC', 2], 'Helmholtz GMC belongs to IMPC group and has order 2'
      assert_equal Consortium['DTCC-Legacy'].consortia_group_and_order, ['Legacy', 3], 'DTCC-Legacy belongs to Legacy group and has order 3'
      assert_equal Consortium['MGP-KOMP'].consortia_group_and_order, ['Other', 4], 'NarLabs belongs to Other group and has order 4'
    end
  end
end
