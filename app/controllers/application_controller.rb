class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private
    # Referenced by config.person_method in config/initializers/rollbar.rb
    # so error reports get attributed to the logged-in user.
    def rollbar_person
      Current.user
    end

    # Surfaces the current user in lograge's structured request log line
    # (see custom_options in config/initializers/lograge.rb).
    def append_info_to_payload(payload)
      super
      payload[:user_id] = Current.user&.id
    end
end
