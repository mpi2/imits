class GeneAssignment < ActiveRecord::Base
  acts_as_reportable
  acts_as_audited


  belongs_to :gene_list
  belongs_to :mi_plan
  belongs_to :status

  validates :gene_list, :presence => true
  validates :mi_plan, :presence => true
  validates :status, :presence => true

  validate do |ga|
    other_ids = GeneAssignment.where(:mi_plan_id => ga.mi_plan_id,
      :gene_list_id => ga.gene_list_id,
    other_ids -= [ga.id]
    if(other_ids.count != 0)
      ga.errors.add(:gene_list, 'gene already is assigned to Gene List')
    end
  end

  after_save :sync_conflicts

  def sync_conflicts
    conflicting_gene_assignments = GeneAssignment.join(plan: :gene).where("gene_assignment.gene_list_id = #{self.gene_list_id} AND genes.marker_symbol = '#{self.marker_symbol}' AND gene_assignments.withdraw = false AND gene_assignments.conflict = false")
    withdrawn_gene_assignment = GeneAssignment.join(plan: :gene).where("gene_assignment.gene_list_id = #{self.gene_list_id} AND genes.marker_symbol = '#{self.marker_symbol}' AND gene_assignments.withdraw = true AND gene_assignments.conflict = true")
    # set conflict flag through SQL update. This ensure that this callback method does not cause an infinite loop when the associated models are saved below.
    conflicting_gene_assignments.update_all(conflict: true)
    withdrawn_gene_assignment.update_all(conflict: false)
    # saving models to ensure status and status stamps are correcly set.
    conflicting_gene_assignment.each{|cga| ga = GeneAssignment.find(cga.id); ga.save!}
    withdrawn_gene_assignment.each{|cga| ga = GeneAssignment.find(cga.id); ga.save!}
  end
  private :sync_conflicts

  def marker_symbol
  end

  def marker_symbol=(arg)
  end
end
