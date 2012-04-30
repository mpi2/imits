require 'mail'
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    begin
      m = Mail::Address.new(value)
      # We must check that value contains a domain and that value is an email address
      r = m.domain && m.address == value
      t = m.__send__(:tree)
      # We need to dig into treetop
      # A valid domain must have dot_atom_text elements size > 1
      # user@localhost is excluded
      # treetop must respond to domain
      # We exclude valid email values like <user@localhost.com>
      # Hence we use m.__send__(tree).domain
      r &&= (t.domain.dot_atom_text.elements.size > 1)
    rescue RuntimeError => e   
      r = false
    end
    record.errors[attribute] << (options[:message] || "is invalid") unless r
  end
end

# Above implementation uses Treetop, regex variant below
#  def validate()
#    email_field = options[:attr]
#    record.errors[email_field] << "is not valid" unless
#      record.send(email_field) =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
#  end
#
# Add to model
#  validates_with EmailValidator, :attr => :email
