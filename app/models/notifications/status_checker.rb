# encoding: utf-8

module Notifications::StatusChecker
  
  def check_statuses
    @storage = Hash.new
    this_gene = self.gene
    
      
      this_gene.mi_plans.each do |this_plan|
        relevant_status = this_plan.relevant_status_stamp
        if self.last_email_sent
          if relevant_status.date > self.last_email_sent.beginning_of_day
            @storage[relevant_status.order_by] = relevant_status
          end
        elsif self.welcome_email_sent
          if relevant_status.date > self.welcome_email_sent.beginning_of_day
            @storage[relevant_status.order_by] = relevant_status
          end 
        end
      end
     
      return @storage
  end
  
end
