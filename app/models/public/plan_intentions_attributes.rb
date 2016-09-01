module Public::PlanIntentionsAttributes

  JSON_OPTIONS = {
    :except => ['intention_id', 'plan_id', 'status_id', 'sub_project_id'],
#    :include => {},
    :methods => ['intention_name', 'status_name', 'sub_project_name']
  }

  def plan_intentions_attributes
    return plan_intentions.as_json(JSON_OPTIONS)
  end
end
