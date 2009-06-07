class CreateWebaddresses < ActiveRecord::Migration
  def self.up
    create_table :webaddresses do |t|
      t.column :site,       :string
      t.column :path,       :string
      t.column :reason,     :string
      t.column :ticket,     :string
      t.column :user_id,    :integer,   :null => false
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table :webaddresses
  end
end
