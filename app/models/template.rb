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

  # JSONにシリアライズされる際に、上記で定義した安全なアクセサを使用するよう強制する
  def as_json(options = {})
    # Controllerの `as_json(only: [:id, :name, :range, :mapping])` に対応
    super(options).tap do |json|
      # カスタムアクセサの値を強制的にJSONにセットする
      # これにより、たとえDB値がnullでも、アクセサが返す安全なハッシュが使用される
      json['range']   = self.range
    end
  end
end
