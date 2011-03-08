class CreateEmiStatusDict < ActiveRecord::Migration
  def self.up
    create_table "emi_status_dict", :force => true do |t|
      t.string  "name",        :limit => 512
      t.string  "description", :limit => 4000
      t.decimal "order_by"
      t.boolean "active"
    end

    add_index "emi_status_dict", ["name"], :unique => true

    add_foreign_key 'emi_attempt', 'status_dict_id', 'emi_status_dict'
  end

  def self.down
    execute 'drop table emi_status_dict cascade'
  end
end
