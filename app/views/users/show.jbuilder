if params[:id] == current_user.uid
  json.partial! 'user', user: @user
else
  json.partial! 'public_user', user: @user
end
