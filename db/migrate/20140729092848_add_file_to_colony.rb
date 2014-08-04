class AddFileToColony < ActiveRecord::Migration
  def self.up
    add_attachment :colonies, :trace_file
  end

  def self.down
    remove_attachment :colonies, :trace_file
  end
end
