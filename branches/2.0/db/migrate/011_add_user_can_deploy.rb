class AddUserCanDeploy < ActiveRecord::Migration
  def self.up
    add_column :users, :can_deploy, :boolean, :default => true
  end

  def self.down
    remove_column :users, :can_deploy
  end
end
