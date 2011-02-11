module EmiAttemptsHelper

  def emi_attempts_table(emi_attempts_instance_variable_name = :emi_attempts)
    netzke(emi_attempts_instance_variable_name,
      :class_name => "Basepack::GridPanel", :model => "EmiAttempt",
      :columns => [
        :clone_name
      ]
    )

  end
end
