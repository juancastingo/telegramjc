class User < ApplicationRecord
  has_and_belongs_to_many :lists, -> { distinct }
  validates :name, uniqueness: true
end
