# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :name
  end
end

class User < ActiveRecord::Base
  has_many :posts

  def external_call
    ActiveSupport::Notifications.instrument("n_plus_one_control.external_event") { true }
  end
end

FactoryGirl.define do
  factory :user do
    name "John"
  end
end
