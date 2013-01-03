require 'test_helper'

class PhenotypeAttempt::DistributionCentreTest < ActiveSupport::TestCase
  context 'PhenotypeAttempt::DistributionCentre' do

    should have_db_column :created_at

    should have_db_column :id
    should have_db_column :start_date
    should have_db_column :end_date
    should have_db_column :is_distributed_by_emma

    should belong_to :phenotype_attempt
    should belong_to :centre
    should belong_to :deposited_material

    context '#centre_name virtual attribute' do
      should 'access association by attribute' do
        dc = PhenotypeAttempt::DistributionCentre.new
        dc.centre_name = 'WTSI'
        assert_equal 'WTSI', dc.centre_name
        assert_equal Centre.find_by_name!('WTSI').id, dc.centre.id
      end
    end

    context '#deposited_material_name virtual attribute' do
      should 'access association by attribute' do
        dc = PhenotypeAttempt::DistributionCentre.new
        dc.deposited_material_name = 'Frozen embryos'
        assert_equal 'Frozen embryos', dc.deposited_material_name
        assert_equal DepositedMaterial.find_by_name!('Frozen embryos').id, dc.deposited_material.id
      end
    end

    should 'serialize correctly' do
      pt = Factory.create :phenotype_attempt_status_pdc
      dc = TestDummy.create :phenotype_attempt_distribution_centre,
              'WTSI',
              'Live mice',
              :start_date => '2012-01-01',
              :end_date => '2012-01-02',
              :is_distributed_by_emma => true,
              :phenotype_attempt => pt

      expected = {
        'id' => dc.id,
        'centre_name' => 'WTSI',
        'deposited_material_name' => 'Live mice',
        'is_distributed_by_emma' => true,
        'distribution_network' => 'EMMA',
        'start_date' => '2012-01-01',
        'end_date' => '2012-01-02',
        '_destroy' => false
      }

      assert_equal expected, JSON.parse(dc.to_json)
    end

    context '#distribution_network' do
      setup do
        @dc = Factory.create :phenotype_attempt_distribution_centre
      end

      should "be set to 'EMMA' when is_distributed_by_emma is set to true" do
        @dc.is_distributed_by_emma = true
        @dc.save!
        assert_equal "EMMA", @dc.distribution_network
        assert_equal true, @dc[:is_distributed_by_emma]
      end

      should "set is_distributed_by_emma to false if #distribution_network is not 'EMMA'" do
        @dc.distribution_network = 'MMRRC'
        @dc.save!
        assert_equal "MMRRC", @dc.distribution_network
        assert_equal false, @dc[:is_distributed_by_emma]
      end
    end

  end
end