class CreateConsortia < ActiveRecord::Migration
  class Consortium < ActiveRecord::Base
    has_many :mi_attempts
  end

  class MiAttempt < ActiveRecord::Base
    belongs_to :consortium
    belongs_to :production_centre, :class_name => 'Centre'
    belongs_to :es_cell
  end

  class EsCell < ActiveRecord::Base
    belongs_to :pipeline
    has_many :mi_attempts
  end

  class Pipeline < ActiveRecord::Base
  end

  class Centre < ActiveRecord::Base
  end

  def self.up
    create_table :consortia do |t|
      t.string :name, :null => false, :size => 15
      t.timestamps
    end
    add_index :consortia, :name, :unique => true

    # Create the basic consortia rows

    eumodic = Consortium.find_or_create_by_name('EUCOMM-EUMODIC')
    mgp     = Consortium.find_or_create_by_name('MGP')
    bash    = Consortium.find_or_create_by_name('BASH')

    # Link to mi_attempts

    add_column :mi_attempts, :consortium_id, :integer
    add_foreign_key :mi_attempts, :consortia

    MiAttempt.all.each do |mi|
      if mi.production_centre.name == 'WTSI'
        if mi.es_cell.pipeline.name =~ /KOMP/
          mi.consortium_id = mgp.id
        else
          mi.consortium_id = eumodic.id
        end
      else
        mi.consortium_id = eumodic.id
      end
      mi.save!
    end

    execute('alter table mi_attempts alter column consortium_id set not null')
  end

  def self.down
    remove_foreign_key :mi_attempts, :consortia
    remove_column :mi_attempts, :consortium_id

    remove_index :consortia, :column => :name
    drop_table :consortia
  end
end
