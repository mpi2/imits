class Kermits2::Migration
  def self.run
    Old::Centre.all.each do |old_centre|
      Centre.create!(:name => old_centre.name)
    end
  end
end
