class AddDefaultFilterToUserTable < ActiveRecord::Migration

  def self.up
    add_column :users, :filter_by_centre_id, :string

    sql = <<-EOF
      UPDATE users SET filter_by_centre_id = production_centre_id WHERE production_centre_id != #{ Centre.find_by_name('EBI - Informatics Support').id };
    EOF

    ActiveRecord::Base.connection.execute(sql)
  end

  def self.down
    remove_column :users, :filter_by_centre_id
  end

end
