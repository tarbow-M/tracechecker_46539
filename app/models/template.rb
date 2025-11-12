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

  # JSONにシリアライズされる際に、上記で定義した安全なアクセサを使用するよう強制する
  def as_json(options = {})
    # Controllerの as_json(only: [:id, :name, :range, :mapping]) の空データに対応
    options[:only] ||= []
    
    super(options).tap do |json|
      json['range']   = range   # カスタムアクセサの値をセット
      json['mapping'] = mapping # カスタムアクセサの値をセット
    end
  end
end
