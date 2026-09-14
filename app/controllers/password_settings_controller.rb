class PasswordSettingsController < ApplicationController
  def edit
  end

  def update
    if !Current.user.authenticate(params[:current_password])
      redirect_to edit_password_setting_path, alert: "Current password is incorrect."
    elsif Current.user.update(params.permit(:password, :password_confirmation))
      redirect_to edit_password_setting_path, notice: "Password updated."
    else
      redirect_to edit_password_setting_path, alert: Current.user.errors.full_messages.to_sentence
    end
  end
end
