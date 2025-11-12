class Template < ApplicationRecord
  # --- Associations ---
  belongs_to :user
  validates :name, presence: true

  # --- PostgreSQLのJsonb型に対応するためのメソッド ---
  # rangeがnilの場合に空のハッシュを返す
  def range
    data = read_attribute(:range) || {}
    # range.a や range.b が nil になることを防ぐ
    data['a'] ||= []
    data['b'] ||= []
    data
  end

  # mappingがnilの場合に空のハッシュを返す
  def mapping
    read_attribute(:mapping) || {}
  end
end
