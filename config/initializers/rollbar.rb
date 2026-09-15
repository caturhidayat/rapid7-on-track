Rollbar.configure do |config|
  config.access_token = ENV["ROLLBAR_ACCESS_TOKEN"]

  # Never report from the test suite, even if a real token is loaded via
  # dotenv (it's configured for the :test group too) -- specs shouldn't
  # send real errors to the dashboard.
  config.enabled = !Rails.env.test?

  # Set environment from Rails
  config.environment = ENV["ROLLBAR_ENVIRONMENT"].presence || Rails.env

  # Optional: Set code version
  config.code_version = ENV["GIT_SHA"]

  # Attach the current user to reported errors via ApplicationController#rollbar_person
  # (this app uses Current.user, not a current_user method).
  config.person_method = "rollbar_person"
  config.person_id_method = "id"
  config.person_email_method = "email_address"

  # Add exception exclusions
  config.exception_level_filters.merge!(
    "ActionController::RoutingError" => "ignore"
  )

  # Enable async reporting (optional, recommended)
  # config.use_async = true
end
