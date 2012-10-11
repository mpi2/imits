module StatusInterface
  extend ActiveSupport::Concern

  module ClassMethods
    def [](name)
      status = self.where('name = ? OR code = ?', name, name).first
      raise ActiveRecord::RecordNotFound, "No status with name or code of #{name}" if ! status
      return status
    end
  end
end
