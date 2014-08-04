class CreateColonyTraceFiles < ActiveRecord::Migration
  def self.up
    create_table :trace_files do |t|
      t.integer    :colony_id
      t.string     :style
      t.binary     :file_contents

      t.timestamps
    end
  end

  def self.down
    drop_table :trace_files
  end
end
