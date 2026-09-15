Rollbar.configure do |config|
  config.access_token = ENV["ROLLBAR_ACCESS_TOKEN"]

  # Only report when a token is actually configured, and never from the test suite.
  config.enabled = ENV["ROLLBAR_ACCESS_TOKEN"].present? && !Rails.env.test?

  config.environment = ENV.fetch("ROLLBAR_ENVIRONMENT", Rails.env)

  # Attach the current user to reported errors via Current.user (this app doesn't
  # define a `current_user` controller method, so point Rollbar at Current.user).
  config.person_method = "rollbar_person"
  config.person_id_method = "id"
  config.person_email_method = "email_address"

  # Expected/handled exceptions that don't need to page anyone.
  config.exception_level_filters.merge!(
    "ActiveRecord::RecordNotFound" => "warning",
    "ActionController::RoutingError" => "warning",
    "ActionController::InvalidAuthenticityToken" => "warning"
  )
end
