class AddAgingFieldsToPhenotype < ActiveRecord::Migration

  def self.up
   sql_update = <<-EOF
     DELETE FROM schema_migrations
     WHERE version = '201604011125302';
   EOF

   ActiveRecord::Base.connection.execute(sql_update)

    add_column :phenotyping_productions, :selected_for_late_adult_phenotyping, :boolean, :default => false
    add_column :phenotyping_productions, :late_adult_phenotyping_started, :boolean, :default => false
    add_column :phenotyping_productions, :late_adult_phenotyping_complete, :boolean, :default => false
    add_column :phenotyping_productions, :late_adult_is_active, :boolean, :default => true
    add_column :phenotyping_productions, :late_adult_report_to_public, :boolean, :default => true
    add_column :phenotyping_productions, :late_adult_phenotyping_experiments_started, :date
    add_column :phenotyping_productions, :late_adult_status_id, :integer

    create_table :phenotyping_production_late_adult_statuses do |t|
      t.string :name, :null => false, :limit => 50
      t.string :order_by, :integer
      t.string :code, :string, :limit => 10

      t.timestamps
    end

    create_table :phenotyping_production_late_adult_status_stamps do |table|
      table.integer :phenotyping_production_id, :null => false
      table.integer :status_id, :null => false

      table.timestamps
    end

    add_foreign_key :phenotyping_productions, :phenotyping_production_late_adult_statuses, column: :late_adult_status_id, name: :fk_phenotyinging_production_late_adult_status
    add_foreign_key :phenotyping_production_late_adult_status_stamps, :phenotyping_production_late_adult_statuses, column: :status_id, name: :fk_late_adult_pp_status_stamps_status
    add_foreign_key :phenotyping_production_late_adult_status_stamps, :phenotyping_productions,  name: :fk_late_adult_pp_status_stamps_pp

    statuses = [{'name' => 'Not Registered For Late Adult Phenotyping','pdlanotr' => '', 'order_by' => 200}, 
                {'name' => 'Registered for Late Adult Phenotyping Production','pdlar' => '', 'order_by' => 610}, 
                {'name' => 'Late Adult Phenotyping Started','code' => 'pdlas', 'order_by' => 630},
                {'name' => 'Late Adult Phenotyping Complete','code' => 'pdlac', 'order_by' => 640},
                {'name' => 'Late Adult Phenotype Production Aborted','pdlaa' => 'cof', 'order_by' => 213}]
    statuses.each do |status|
      if PhenotypingProduction::LateAdultStatus.find_by_name(status['name']).blank?
        pplas = PhenotypingProduction::LateAdultStatus.new
        pplas.name = status['name']
        pplas.code = status['code']
        pplas.order_by = status['order_by']
        pplas.save
      end
    end

    sql = <<-EOF
      UPDATE phenotyping_productions SET late_adult_status_id = #{PhenotypingProduction::LateAdultStatus.find_by_name('Not Registered For Late Adult Phenotyping').id};

      INSERT INTO phenotyping_production_late_adult_status_stamps(phenotyping_production_id, status_id, created_at, updated_at)
      SELECT phenotyping_productions.id, #{PhenotypingProduction::LateAdultStatus.find_by_name('Not Registered For Late Adult Phenotyping').id}, NOW(), NOW() FROM phenotyping_productions
      ;
    EOF

    ActiveRecord::Base.connection.execute(sql)

  end

  def self.down
    remove_foreign_key :phenotyping_productions, name: :fk_phenotyinging_production_late_adult_status
    remove_foreign_key :phenotyping_production_late_adult_status_stamps, name: :fk_late_adult_pp_status_stamps_status
    remove_foreign_key :phenotyping_production_late_adult_status_stamps, name: :fk_late_adult_pp_status_stamps_pp

    drop_table :phenotyping_production_late_adult_status_stamps
    drop_table :phenotyping_production_late_adult_statuses

    remove_column :phenotyping_productions, :late_adult_phenotyping_started
    remove_column :phenotyping_productions, :late_adult_phenotyping_complete
    remove_column :phenotyping_productions, :selected_for_late_adult_phenotyping
    remove_column :phenotyping_productions, :late_adult_is_active
    remove_column :phenotyping_productions, :late_adult_report_to_public
    remove_column :phenotyping_productions, :late_adult_phenotyping_experiments_started
    remove_column :phenotyping_productions, :late_adult_status_id
  end

end
