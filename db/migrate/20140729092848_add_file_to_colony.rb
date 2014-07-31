class AddFileToColony < ActiveRecord::Migration
  def self.up
    #add_column :colonies, :trace_filename, :string, :limit => 255

    # see http://edgeguides.rubyonrails.org/active_record_postgresql.html#bytea
    #add_column :colonies, :trace_file, :binary

    add_attachment :colonies, :tfile
  end

  def self.down
   # remove_column :colonies, :trace_filename
   # remove_column :colonies, :trace_file

    remove_attachment :colonies, :tfile
  end
end
