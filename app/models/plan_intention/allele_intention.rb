# encoding: utf-8

class PlanIntention::AlleleIntention < ActiveRecord::Base
  acts_as_reportable

  belongs_to :plan_intentions

end

# == Schema Information
#
# Table name: plan_intention_allele_intentions
#
#  id                     :integer          not null, primary key
#  plan_intention_id      :integer          not null
#  priority_id            :integer
#  bespoke_allele         :boolean          default(FALSE), not null
#  recovery_allele        :boolean          default(FALSE), not null
#  conditional_allele     :boolean          default(FALSE), not null
#  non_conditional_allele :boolean          default(FALSE), not null
#  cre_knock_in_allele    :boolean          default(FALSE), not null
#  cre_bac_allele         :boolean          default(FALSE), not null
#  deletion_allele        :boolean          default(FALSE), not null
#  point_mutation         :boolean          default(FALSE), not null
#  comment                :text
#
