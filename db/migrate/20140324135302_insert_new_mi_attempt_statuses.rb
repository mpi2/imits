class InsertNewMiAttemptStatuses < ActiveRecord::Migration

  def self.up
    statuses = [{'name' => 'Founder obtained','code' => 'fod', 'order_by' => 231}, {'name' => 'Chimeras/Founder obtained','code' => 'cof', 'order_by' => 229}]
    statuses.each do |status|
      if MiAttempt::Status.find_by_name(status['name']).blank?
        ms = MiAttempt::Status.new
        ms.name = status['name']
        ms.code = status['code']
        ms.order_by = status['order_by']
        ms.save
      end
    end
  end

  def self.down
    statuses = ['Founder obtained','Chimeras/Founder obtained']
    statuses.each do |status|
      if !MiAttempt::Status.find_by_name(status).blank?
        MiAttempt::Status.find_by_name(status).delete
      end
    end
  end
end
