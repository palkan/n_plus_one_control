# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :posts do |t|
    t.string :title
    t.integer :user_id
  end
end

class Post < ActiveRecord::Base
  belongs_to :user
end

FactoryGirl.define do
  factory :post do
    title "Title"
    user
  end
end
