class CreateHosts < ActiveRecord::Migration
  def self.up
    create_table :hosts do |t|
      t.column :hostname,        :string
      t.column :username,        :string
      t.column :password,        :string
      t.column :enable_password, :string
      t.column :dirty,           :boolean
    end
  end

  def self.down
    drop_table :hosts
  end
end
