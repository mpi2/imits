class SetDistributionNetworkFromEmmaBoolean < ActiveRecord::Migration
  def self.up

    ##
    ## Set distribution_network to 'EMMA' if 'is_distributed_by_emma' is true.
    ##

    MiAttempt::DistributionCentre.reset_column_information
    PhenotypeAttempt::DistributionCentre.reset_column_information

    (MiAttempt::DistributionCentre.all + PhenotypeAttempt::DistributionCentre.all).each do |dc|
      if dc[:is_distributed_by_emma]
        dc.distribution_network = 'EMMA'
        dc.save! rescue false
      end
    end
  end

  def self.down
  end
end
