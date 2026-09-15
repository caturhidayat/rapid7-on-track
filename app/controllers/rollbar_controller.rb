# Dev-only endpoint (see config/routes.rb) for confirming Rollbar delivery
# end-to-end: hit GET /rollbar/test and check the Rollbar dashboard.
class RollbarController < ApplicationController
  allow_unauthenticated_access only: :test

  def test
    raise "Rollbar test error triggered from RollbarController#test"
  end
end
