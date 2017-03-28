class List < ApplicationRecord
  has_and_belongs_to_many :users, -> { distinct }
  belongs_to :group
  validates :name, uniqueness: true, presence: true
end
