class CreatePerCentre < ActiveRecord::Migration
  def self.up
    create_table 'per_centre' do |t|
      t.string   'name',         :limit => 128
      t.integer  'creator_id'
      t.datetime 'edit_date'
      t.string   'edited_by',    :limit => 128
      t.integer  'check_number'
      t.datetime 'created_date'
    end

    add_foreign_key 'emi_event', 'centre_id', 'per_centre'
    add_foreign_key 'emi_event', 'distribution_centre_id', 'per_centre'
  end

  def self.down
    execute 'drop table per_centre cascade'
  end
end
