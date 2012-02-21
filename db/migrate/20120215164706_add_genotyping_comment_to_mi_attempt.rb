class AddGenotypingCommentToMiAttempt < ActiveRecord::Migration
  def self.up
    add_column :mi_attempts, :genotyping_comment, :string, :limit => 512
  end

  def self.down
    remove_column :mi_attempts, :genotyping_comment
  end
end
