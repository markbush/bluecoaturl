class AddCategoryImage < ActiveRecord::Migration
  def self.up
    add_column :categories, :image, :binary
  end

  def self.down
    remove_column :categories, :image
  end
end
