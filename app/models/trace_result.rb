class TraceResult < ApplicationRecord
  belongs_to :archived_result

  validates :key, presence: true
  validates :flag, presence: true
end
