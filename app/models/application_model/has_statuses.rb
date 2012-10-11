module ApplicationModel::HasStatuses
  extend ActiveSupport::Concern

  module ClassMethods
    def status_class; return self.const_get('Status'); end
  end

  def status_class; self.class.status_class; end

  def has_status?(status)
    if status.kind_of?(String) or status.kind_of?(Symbol)
      status_name = status
      status = status_class.find_by_code(status_name)
      if ! status
        status = status_class.find_by_name(status_name)
      end
    end
    return status_stamps.where(:status_id => status.id).size != 0
  end
end
