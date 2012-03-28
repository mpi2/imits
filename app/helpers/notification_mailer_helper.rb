module NotificationMailerHelper
  def registration_text_selection(relevant_status)
    case relevant_status[:stamp_type]
      when "MiPlan::StatusStamp"
        case relevant_status[:status]
         when "Assigned - ES Cell QC In Progress"
           render "notification_mailer/assigned_qc_in_progress.text.erb", :relevant_status => relevant_status
         when "Assigned - ES Cell QC Complete"
           render "notification_mailer/assigned_qc_complete.text.erb", :relevant_status => relevant_status
         when "Interest", "Conflict", "Inspect - Conflict", "Inspect - MI Attempt", "Inspect - GLT Mouse", "Assigned", "Assigned", "Aborted - ES Cell QC Failed"
           render "notification_mailer/interest.text.erb", :relevant_status => relevant_status
         when "Inactive", "Withdrawn"
           render "notification_mailer/inactive.text.erb", :relevant_status => relevant_status
         else
           render "notification_mailer/inactive.text.erb", :relevant_status => relevant_status
        end
      when "MiAttempt::StatusStamp"
        case relevant_status[:status]
         when "Micro-injection in progress"
           render "notification_mailer/microinjection_in_progress.text.erb", :relevant_status => relevant_status
         when "Genotype confirmed"
           render "notification_mailer/genotype_confirmed.text.erb", :relevant_status => relevant_status
         when "Micro-injection aborted"
           render "notification_mailer/interest.text.erb", :relevant_status => relevant_status
         when "Chimeras obtained"
           render "notification_mailer/chimeras_obtained.text.erb", :relevant_status => relevant_status
         else
           render "notification_mailer/inactive.text.erb", :relevant_status => relevant_status
        end
      when "PhenotypeAttempt::StatusStamp"
        case relevant_status[:status]
         when "Phenotype Attempt Aborted", "Phenotype Attempt Registered"
           render "notification_mailer/genotype_confirmed.text.erb", :relevant_status => relevant_status
         when "Rederivation Started"
           render "notification_mailer/rederivation_started.text.erb", :relevant_status => relevant_status
         when "Rederivation Complete"
           render "notification_mailer/rederivation_complete.text.erb", :relevant_status => relevant_status
         when "Cre Excision Started"
           render "notification_mailer/cre_excision_started.text.erb", :relevant_status => relevant_status
         when "Cre Excision Complete"
           render "notification_mailer/cre_excision_complete.text.erb", :relevant_status => relevant_status
         when "Phenotyping Started"
           render "notification_mailer/phenotyping_started.text.erb", :relevant_status => relevant_status
         when "Phenotyping Complete"
           render "notification_mailer/phenotyping_complete.text.erb", :relevant_status => relevant_status
         else
           render "notification_mailer/inactive.text.erb", :relevant_status => relevant_status
        end
       else
         render "notification_mailer/inactive.text.erb", :relevant_status => relevant_status 
         
    end
  
  end
end
