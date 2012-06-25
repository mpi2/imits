class AddDeleterStrain < ActiveRecord::Migration

  def self.up
    add_column :phenotype_attempts, :deleter_strain_id, :integer

    create_table :deleter_strains do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    remove_column :phenotype_attempts, :deleter_strain_id
    drop_table :deleter_strains
  end
end
