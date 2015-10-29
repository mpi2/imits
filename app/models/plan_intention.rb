class PlanIntention < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute

end