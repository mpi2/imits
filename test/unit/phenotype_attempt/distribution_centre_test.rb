require 'test_helper'

class PhenotypeAttempt::DistributionCentreTest < ActiveSupport::TestCase
  context 'PhenotypeAttempt::DistributionCentre' do

    should have_db_column :created_at

    should have_db_column :id
    should have_db_column :start_date
    should have_db_column :end_date
    should have_db_column :is_distributed_by_emma
    should have_db_column :available

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

    context '#distribution centre available and reconciled validation checks' do

      setup do
        @pa = Factory.create :phenotype_attempt_status_pdc
        @dc = @pa.distribution_centres.first
      end

      should 'set available flag to true if distribution centre not KOMP Repo or UCD' do
        wtsi_centre      = Centre.find_by_name('WTSI')
        @dc.centre       = wtsi_centre
        @dc.save!
        assert_equal true, @dc.available
      end

      should 'set available flag to false if distribution centre changes to KOMP Repo' do
        wtsi_centre      = Centre.find_by_name('WTSI')
        @dc.centre       = wtsi_centre
        @dc.save!
        assert_equal true, @dc.available

        komp_repo_centre = Centre.find_by_name('KOMP Repo')
        @dc.centre       = komp_repo_centre
        @dc.save!
        assert_equal false, @dc.available
      end

    end

    context '#distribution centre before save checks' do

      setup do
        @pa = Factory.create :phenotype_attempt_status_pdc
        @dc = @pa.distribution_centres.first
      end

      should 'error when distribution network is blank and distribution centre is UCD' do
        ucd_centre               = Centre.find_by_name('UCD')
        @dc.centre               = ucd_centre
        @dc.distribution_network = nil

        exception = assert_raises(PhenotypeAttempt::DistributionCentre::UnsuitableDistributionCentreError) { @dc.save! }
        assert_equal( "When the distribution network is blank use distribution centre KOMP Repo rather than UCD.", exception.message )
      end

      should 'save normally for blank network and centre KOMP Repo' do
        komp_repo_centre         = Centre.find_by_name('KOMP Repo')
        @dc.centre               = komp_repo_centre
        @dc.distribution_network = nil
        assert_nothing_raised do
          @dc.save!
        end
        @dc.reload

        assert_equal 'KOMP Repo', @dc.centre.name
      end

      should 'save normally for blank network and centre other than UCD or KOMP Repo' do
        tcp_centre               = Centre.find_by_name('TCP')
        @dc.centre               = tcp_centre
        @dc.distribution_network = nil
        assert_nothing_raised do
          @dc.save!
        end
        @dc.reload

        assert_equal 'TCP', @dc.centre.name
      end

      should 'save normally for network MMRRC and centre KOMP Repo' do
        komp_repo_centre         = Centre.find_by_name('KOMP Repo')
        @dc.centre               = komp_repo_centre
        @dc.distribution_network = 'MMRRC'
        assert_nothing_raised do
          @dc.save!
        end
        @dc.reload

        assert_equal 'MMRRC', @dc.distribution_network
        assert_equal 'KOMP Repo', @dc.centre.name
      end

      should 'error for network CMMR and centre KOMP Repo' do
        komp_repo_centre         = Centre.find_by_name('KOMP Repo')
        @dc.centre               = komp_repo_centre
        @dc.distribution_network = 'CMMR'

        exception = assert_raises(PhenotypeAttempt::DistributionCentre::UnsuitableDistributionNetworkError) { @dc.save! }
        assert_equal( "The distribution network cannot be set to anything other than MMRRC for distribution centres KOMP Repo or UCD. If you want to indicate that you're distributing to another network then you need to create another distribution centre for your production centre and then select the new network.", exception.message )
      end

      should 'error for network EMMA and centre KOMP Repo' do
        komp_repo_centre         = Centre.find_by_name('KOMP Repo')
        @dc.centre               = komp_repo_centre
        @dc.distribution_network = 'EMMA'

        exception = assert_raises(PhenotypeAttempt::DistributionCentre::UnsuitableDistributionNetworkError) { @dc.save! }
        assert_equal( "The distribution network cannot be set to anything other than MMRRC for distribution centres KOMP Repo or UCD. If you want to indicate that you're distributing to another network then you need to create another distribution centre for your production centre and then select the new network.", exception.message )
      end

    end

  end
end