class SetPhenoTypeOnlyOnMiPlans < ActiveRecord::Migration
  def self.up
    MiPlan.transaction do
      PhenotypeAttempt.all.each do |p|
        if p.mi_plan.consortium != p.mi_attempt.consortium
          mi_plan = p.mi_plan
          mi_plan.phenotype_only = true
          mi_plan.save!
        end
      end
    end
  end

  def self.down
  end
end
