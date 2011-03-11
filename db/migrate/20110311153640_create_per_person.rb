class CreatePerPerson < ActiveRecord::Migration
  def self.up
    create_table "per_person" do |t|
      t.string   "first_name",    :limit => 128
      t.string   "last_name",     :limit => 128
      t.string   "password_hash", :limit => 128
      t.string   "user_name",     :limit => 32
      t.string   "email",         :limit => 1024
      t.string   "address",       :limit => 2048
      t.integer  "centre_id",                     :precision => 38, :scale => 0
      t.integer  "creator_id",                    :precision => 38, :scale => 0
      t.datetime "created_date"
      t.string   "edited_by",     :limit => 128
      t.datetime "edit_date"
      t.integer  "check_number",                  :precision => 38, :scale => 0, :default => 0
      t.boolean  "active",                        :precision => 1,  :scale => 0
      t.boolean  "hidden",                        :precision => 1,  :scale => 0
    end

    add_index "per_person", ["user_name"], :unique => true
  end

  def self.down
    drop_table 'per_person'
  end
end
