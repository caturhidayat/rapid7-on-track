Rails.application.configure do
  # One structured JSON line per request instead of Rails' multi-line
  # Started/Processing/Completed output. Kept off in development so local
  # logs stay human-readable; on in production for log-aggregator ingestion.
  config.lograge.enabled = Rails.env.production?
  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.custom_options = lambda do |event|
    {
      request_id: event.payload[:headers]["action_dispatch.request_id"],
      remote_ip: event.payload[:headers]["action_dispatch.remote_ip"].to_s,
      user_id: event.payload[:user_id],
      params: event.payload[:params]&.except(
        "controller", "action", "authenticity_token",
        "password", "password_confirmation", "current_password"
      )
    }.compact
  end

  config.lograge.ignore_actions = [ "Rails::HealthController#show" ]
end
