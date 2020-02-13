if params[:id] == current_user.uid
  json.partial! 'partials/user_details', user: @user
else
  json.partial! 'partials/public_user_details', user: @user
end
