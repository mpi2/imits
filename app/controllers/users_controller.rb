class UsersController < Devise::RegistrationsController
  include ActionView::Helpers::TagHelper

  layout :layout_by_referer

  prepend_before_filter :authenticate_scope!, :only => [:show, :update]

  def show
    render_with_scope :edit
  end

  def index
    @users = User.all
    respond_with @users.to_json(:only => [:id, :production_centre_id], :methods => [:production_centre_name])
  end

  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)

    user_params = params[:user]

    if user_params[:password].blank?
      user_params.delete(:password)
      user_params.delete(:password_confirmation) if user_params[:password_confirmation].blank?
    end

    if session[:masquerade] || current_user.admin?
      resource.admin = params[:user][:admin]
    end

    if resource.update_attributes(user_params)
      set_flash_message :notice, :updated if is_navigational_format?
      sign_in resource_name, resource, :bypass => true
      respond_with resource, :location => user_path(:redirect => params[:redirect])
    else
      errors = content_tag('ul', resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join.html_safe)
      sentence = I18n.translate("errors.messages.not_saved", :count => resource.errors.count)
      flash[:alert] = "#{sentence}<br\>#{errors}".html_safe if is_navigational_format?
      clean_up_passwords(resource)
      respond_with_navigational(resource){ render_with_scope :edit }
    end
  end

  def password_reset
    if request.post?
      if @user = User.find_by_email(params[:email])
        @user.send_reset_password_instructions
        redirect_to new_user_session_path, :notice => "You will receive an email shortly with instructions on how to reset your password."
      else
        flash[:alert] = "Your password could not be reset at this time. Please re-enter your email address, or contact support."
      end
    end
  end

  private

    def layout_by_referer
      targ_rep? ? 'targ_rep' : 'application'
    end

    def targ_rep?
      params[:redirect] == 'targ_rep'
    end

end
