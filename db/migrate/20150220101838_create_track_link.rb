class CreateTrackLink < ActiveRecord::Migration
  def self.up
    create_table :track_links do |t|
      t.string :ip_address
      t.string :http_refer
      t.string :link_clicked
      t.string :link_type
      t.integer :year
      t.integer :month
      t.integer :day
      t.datetime :created_at
    end
  end

  def self.down
    drop_table :track_links
  end
end
