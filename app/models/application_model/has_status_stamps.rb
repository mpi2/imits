module ApplicationModel::HasStatusStamps
  def has_status?(status)
    return status_stamps.where(:status_id => status.id).size != 0
  end
end
