class History < ActiveRecord::Base
  belongs_to :webaddress
  belongs_to :user
end
