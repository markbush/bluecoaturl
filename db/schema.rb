# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 12) do

  create_table "categories", :force => true do |t|
    t.string "name"
    t.binary "image"
    t.string "description"
  end

  create_table "categories_webaddresses", :id => false, :force => true do |t|
    t.integer "category_id"
    t.integer "webaddress_id"
  end

  add_index "categories_webaddresses", ["category_id", "webaddress_id"], :name => "index_categories_webaddresses_on_category_id_and_webaddress_id", :unique => true
  add_index "categories_webaddresses", ["webaddress_id"], :name => "index_categories_webaddresses_on_webaddress_id"

  create_table "histories", :force => true do |t|
    t.integer  "webaddress_id", :null => false
    t.integer  "user_id",       :null => false
    t.text     "reason"
    t.datetime "created_at"
  end

  create_table "hosts", :force => true do |t|
    t.string  "hostname"
    t.string  "username"
    t.string  "password"
    t.string  "enable_password"
    t.boolean "dirty"
  end

  create_table "schema_info", :id => false, :force => true do |t|
    t.integer "version"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string  "name"
    t.string  "hashed_password"
    t.string  "salt"
    t.boolean "admin"
    t.boolean "enabled",         :default => true
    t.boolean "can_deploy",      :default => true
  end

  create_table "webaddresses", :force => true do |t|
    t.string   "site"
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
