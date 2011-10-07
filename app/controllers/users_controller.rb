class UsersController < Devise::RegistrationsController
  include ActionView::Helpers::TagHelper

  prepend_before_filter :authenticate_scope!, :only => [:show, :update]

  def show
    render_with_scope :edit
  end


  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)

    if resource.update_with_password(params[resource_name])
      set_flash_message :notice, :updated if is_navigational_format?
      sign_in resource_name, resource, :bypass => true
      respond_with resource, :location => user_path
    else
      errors = content_tag('ul', resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join.html_safe)
      sentence = I18n.translate("errors.messages.not_saved", :count => resource.errors.count)
      flash[:alert] = "#{sentence}<br\>#{errors}".html_safe if is_navigational_format?
      clean_up_passwords(resource)
      respond_with_navigational(resource){ render_with_scope :edit }
    end
  end
end
