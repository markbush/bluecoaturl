class AddInitialUser < ActiveRecord::Migration
  def self.up
    user = User.new(:name => 'admin', :password => 'admin', :password_confirmation => 'admin')
    user.admin = true
    user.save
  end

  def self.down
  end
end
