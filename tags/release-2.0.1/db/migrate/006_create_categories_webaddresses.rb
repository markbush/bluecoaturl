class CreateCategoriesWebaddresses < ActiveRecord::Migration
  def self.up
    create_table :categories_webaddresses, :id => false do |t|
      t.column :category_id, :integer
      t.column :webaddress_id,      :integer
    end
    add_index :categories_webaddresses, [:category_id, :webaddress_id], :unique => true
    add_index :categories_webaddresses, :webaddress_id
  end

  def self.down
    remove_index :categories_webaddresses, :column => :webaddress_id
    remove_index :categories_webaddresses, :column => [:category_id, :webaddress_id]
    drop_table   :categories_webaddresses
  end
end
