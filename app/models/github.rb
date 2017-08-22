class Github < ApiClientBase
  def fetch_user(token, uid)
    headers = {
      Authorization: "token #{token}",
      'Content-Type' => 'application/json'
    }
    response = request("/user/#{uid}", headers, {})

    case response.status
    when 200
      user = JSON.parse(response.body)
    when 401
      raise Exceptions::Unauthorized
    when 404
      raise Exceptions::NotFound
    else
      raise Exceptions::InternalServerError
    end

    user
  end
end
