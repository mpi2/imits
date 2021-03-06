class UserMailer < ActionMailer::Base
  default :from => 'impc-imits@ebi.ac.uk'

  def email(params)
    params = params.symbolize_keys
    @email_body = params[:body]
    mail(:to => params[:user].email, :subject => params[:subject])
  end
end
