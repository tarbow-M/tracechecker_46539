class Template < ApplicationRecord
  # --- Associations ---
  belongs_to :user
  validates :name, presence: true

  # --- PostgreSQLのJsonb型に対応するためのメソッド ---
  # rangeがnilの場合に空のハッシュを返す
  def range
    read_attribute(:range) || {}
  end

  # mappingがnilの場合に空のハッシュを返す
  def mapping
    read_attribute(:mapping) || {}
  end
end
