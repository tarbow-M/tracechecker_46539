require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Tracechecker46539
  class Application < Rails::Application
    config.load_defaults 7.1
    config.autoload_lib(ignore: %w(assets tasks))
    # アプリケーションのタイムゾーンを日本時間(JST)に設定
    config.time_zone = 'Tokyo'

  end
end
