# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :posts do |t|
    t.string :title
    t.integer :user_id
    t.integer :category_id
  end
end

class Post < ActiveRecord::Base
  belongs_to :user
  belongs_to :category
end

FactoryGirl.define do
  factory :post do
    title "Title"
    user
    category
  end
end
