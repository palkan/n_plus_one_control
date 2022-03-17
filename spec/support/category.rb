# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :categories do |t|
    t.string :name
  end
end

class Category < ActiveRecord::Base
  has_many :posts
end

FactoryBot.define do
  factory :category do
    name { "Category" }
  end
end
