class AttachMisToMiPlans < ActiveRecord::Migration
  class Gene < ActiveRecord::Base
  end

  class EsCell < ActiveRecord::Base
    belongs_to :gene
  end

  class MiPlanStatus < ActiveRecord::Base
  end

  class MiPlanPriority < ActiveRecord::Base
  end

  class MiPlan < ActiveRecord::Base
    belongs_to :gene
    belongs_to :consortium
    belongs_to :production_centre, :class_name => 'Centre'
    belongs_to :mi_plan_status
    belongs_to :mi_plan_priority
    has_many :mi_attempts
  end

  class MiAttempt < ActiveRecord::Base
    belongs_to :mi_plan
    belongs_to :es_cell
    belongs_to :consortium
    belongs_to :production_centre, :class_name => 'Centre'
  end

  def self.up
    add_column :mi_attempts, :mi_plan_id, :integer
		add_foreign_key :mi_attempts, :mi_plans

    MiAttempt.all.each do |mi_attempt|
      begin
        gene 							= mi_attempt.es_cell.gene
        consortium 				= mi_attempt.consortium
        production_centre = mi_attempt.production_centre

        mi_plan = MiPlan.find_by_gene_id_and_consortium_id_and_production_centre_id( gene, consortium, production_centre )
        if ! mi_plan
          mi_plan = MiPlan.create!(
            :gene 						 	=> gene,
            :consortium 				=> consortium,
            :production_centre 	=> production_centre,
            :mi_plan_status 		=> MiPlanStatus.find_or_create_by_name('Assigned'),
            :mi_plan_priority 	=> MiPlanPriority.find_or_create_by_name('High')
          )
        end

        mi_attempt.mi_plan = mi_plan
        mi_attempt.save!
      rescue Exception => e
        e2 = RuntimeError.new("(#{e.class.name}): On\n\n#{mi_attempt.to_json}\n\n#{e.message}")
        e2.set_backtrace(e.backtrace)
        raise e2
      end
    end

    change_column :mi_attempts, :mi_plan_id, :integer, :null => false
		remove_column :mi_attempts, :consortium_id
    remove_column :mi_attempts, :production_centre_id
  end

  def self.down
    add_column :mi_attempts, :production_centre_id, :integer
    add_foreign_key :mi_attempts, :centres, :column => :production_centre_id

    add_column :mi_attempts, :consortium_id, :integer
    add_foreign_key :mi_attempts, :consortia

    MiPlan.all.each do |mi_plan|
      begin
        mi_plan.mi_attempts.each do |mi_attempt|
          mi_attempt.production_centre = mi_plan.production_centre
          mi_attempt.consortium        = mi_plan.consortium
          mi_attempt.save!
        end
      rescue Exception => e
        e2 = RuntimeError.new("(#{e.class.name}): On\n\n#{mi_plan.to_json}\n\n#{e.message}")
        e2.set_backtrace(e.backtrace)
        raise e2
      end
    end

    change_column :mi_attempts, :production_centre_id, :integer, :null => false
    change_column :mi_attempts, :consortium_id, :integer, :null => false
    remove_column :mi_attempts, :mi_plan_id
  end
end

