class NetzkePersistentArrayAutoModel < ActiveRecord::Base
  establish_connection(
    :adapter => 'sqlite3',
    :database =>  "#{Rails.root}/db/#{Rails.env}.netzke.sqlite3")
end
