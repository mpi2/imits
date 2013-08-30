class AddCassetteTransmissionVerifiedToMiAttempt < ActiveRecord::Migration
  def self.up
    add_column :mi_attempts, :cassette_transmission_verified, :date
    add_column :mi_attempts, :cassette_transmission_verified_auto_complete, :boolean
  end

  def self.down
    remove_column :mi_attempts, :cassette_transmission_verified
    remove_column :mi_attempts, :cassette_transmission_verified_auto_complete
  end
end
