class User < ActiveRecord::Base
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  attr_accessible :email, :password, :password_confirmation

  before_save :remember_me_defaults_to_true

  protected

  def remember_me_defaults_to_true
    self.remember_me = true
  end
end
