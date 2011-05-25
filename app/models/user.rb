class User < ActiveRecord::Base
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  attr_accessible :email, :password, :password_confirmation, :remember_me

  after_initialize do
    self.remember_me = true
  end
end
