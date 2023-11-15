if params[:id] == current_user.uid
  json.partial! 'partials/user', user: @user
else
  json.partial! 'partials/public_user', user: @user
end
