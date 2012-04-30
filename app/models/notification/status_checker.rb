# encoding: utf-8

module Notification::StatusChecker
  
  def check_statuses
    self.relevant_statuses = Array.new
    this_gene = self.gene
    
      this_gene.mi_plans.each do |this_plan|
        relevant_status = this_plan.relevant_status_stamp
        if !(relevant_status[:status].downcase == "micro-injection aborted") || !(relevant_status[:status].downcase == "inactive") || !(relevant_status[:status].downcase == "withdrawn") || !(relevant_status[:status].downcase == "phenotype attempt aborted")
     
          if self.last_email_sent
            if relevant_status[:date] > self.last_email_sent
              self.relevant_statuses.push(relevant_status)
            end
          elsif self.welcome_email_sent
            if relevant_status[:date] > self.welcome_email_sent
              self.relevant_statuses.push(relevant_status)
            end 
          end
        end
       
      end
      return self.relevant_statuses
  end
  
end
