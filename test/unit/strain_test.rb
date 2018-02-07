require 'test_helper'

class StrainTest < ActiveSupport::TestCase
  context 'Strain' do

    context 'database table' do
      should have_db_column(:id).of_type(:integer).with_options(:primary => true)
      should have_db_column(:name).of_type(:string).with_options(:null => false, :limit => 100)
      should have_db_column(:created_at).of_type(:datetime)
      should have_db_column(:updated_at).of_type(:datetime)
      should have_db_column(:mgi_strain_accession_id).of_type(:string).with_options(:limit => 100)
      should have_db_column(:mgi_strain_name).of_type(:string).with_options(:limit => 100)
      should have_db_column(:background_strain).of_type(:boolean).with_options(:default => false)
      should have_db_column(:test_cross_strain).of_type(:boolean).with_options(:default => false)
      should have_db_column(:blast_strain).of_type(:boolean).with_options(:default => false)

      should have_db_index(:name).unique(true)
    end

    context 'Associations and Validations' do
      should validate_presence_of :name
      should validate_uniqueness_of :name
#      should have_many :mi_plans
#      should have_many :colony_distribution_centres
#      should have_many(:tracking_goals)
    end

    should 'have accessible attributes' do
      accessible_attr = [:name, :mgi_strain_name, :mgi_strain_accession_id, :background_strain, :test_cross_strain, :blast_strain]

      accessible_attr.each do |attribute|
        assert_include Strain.accessible_attributes, attribute, "Missing attribute #{attribute}"
      end

      # remove id fields from accessible_attributes by using access_association_by_attribute
      Strain.accessible_attributes.each do |attribute|
        assert_include accessible_attr, attribute.to_sym, "Extra attribute detected #{attribute}"
      end      
    end

    context 'scopes' do
      should 'filter by background_strain' do
        assert_equal [Strain.find_by_name('C57BL/6JcBrd/cBrd')], Strain.background_strain.to_a
      end
      should 'filter by test_cross_strain' do
        assert_equal [Strain.find_by_name('C57BL/6N')], Strain.test_cross_strain.to_a
      end
      should 'filter by blast_strain' do
        assert_equal [Strain.find_by_name('C57Bl/6J Albino')], Strain.blast_strain.to_a
      end
    end

    context 'pretty_drop_down' do
      should 'return name and mgi_accession_id if mgi_accession_id is not null' do
        strain = Strain.find_by_name('C57BL/6N')
        assert_equal 'C57BL/6N:MGI:18', strain.pretty_drop_down
      end
      should 'return name if mgi_strain_accession_id is blank' do
        strain = Strain.find_by_name('C57Bl/6J Albino')
        assert_equal 'C57Bl/6J Albino', strain.pretty_drop_down
      end
    end
  end
end
