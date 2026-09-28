json.partial! 'partials/public_user', user: @user
json.blocking current_user.blocking?(@user)
json.blocked_by current_user.blocked_by?(@user)
json.muting current_user.muting?(@user)
