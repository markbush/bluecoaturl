class CreateHistory < ActiveRecord::Migration
  def self.up
    create_table :histories do |t|
      t.column :webaddress_id,  :integer,   :null => false
      t.column :user_id,        :integer,   :null => false
      t.column :reason,         :text
      t.column :created_at,     :timestamp
    end
    Webaddress.find(:all).each do |w|
      h = History.new :webaddress_id => w.id, :user_id => w.user_id,
                      :reason => (w.ticket.blank? ? w.reason : "[#{w.ticket}] #{w.reason}")
      h.created_at = w.created_at
      h.save
    end
    remove_column :webaddresses, :user_id
    remove_column :webaddresses, :reason
    remove_column :webaddresses, :ticket
    add_column :webaddresses, :updated_at,  :timestamp
  end

  def self.down
    remove_column :webaddresses, :updated_at
    add_column :webaddresses, :user_id, :integer, :null => false
    add_column :webaddresses, :reason,  :text
    add_column :webaddresses, :ticket,  :string
    Webaddress.find(:all).each do |w|
      h = History.find_by_webaddress_id w.id, :order => 'created_at desc'
      w.update_attributes :user_id => h.user_id, :reason => h.reason
    end
    drop_table :histories
  end
end
