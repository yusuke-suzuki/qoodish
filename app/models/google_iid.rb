class GoogleIid < ApiClientBase
  def subscribe_topic(registration_token, topic_name)
    headers = {
      Authorization: "key=#{ENV['FCM_SERVER_KEY']}",
      'Content-Type' => 'application/json'
    }
    response = request("/iid/v1/#{registration_token}/rel/topics/#{topic_name}", headers, {}, :post)

    case response.status
    when 200
      json = JSON.parse(response.body)
    when 401
      raise Exceptions::Unauthorized
    when 404
      raise Exceptions::NotFound
    else
      raise Exceptions::InternalServerError
    end

    json
  end

  def unsubscribe_topic(registration_token, topic_name)
    headers = {
      Authorization: "key=#{ENV['FCM_SERVER_KEY']}",
      'Content-Type' => 'application/json'
    }
    response = request("/iid/v1/#{registration_token}/rel/topics/#{topic_name}", headers, {}, :delete)

    case response.status
    when 200
      json = JSON.parse(response.body)
    when 401
      raise Exceptions::Unauthorized
    when 404
      raise Exceptions::NotFound
    else
      raise Exceptions::InternalServerError
    end

    json
  end

  def bulk_subscribe_topic(registration_tokens, topic_name)
    headers = {
      Authorization: "key=#{ENV['FCM_SERVER_KEY']}",
      'Content-Type' => 'application/json'
    }
    params = {
      to: "/topics/#{topic_name}",
      registration_tokens: registration_tokens
    }
    response = request('/iid/v1:batchAdd', headers, params.to_json, :post)

    case response.status
    when 200
      json = JSON.parse(response.body)
    when 401
      raise Exceptions::Unauthorized
    when 404
      raise Exceptions::NotFound
    else
      raise Exceptions::InternalServerError
    end

    json
  end

  def bulk_unsubscribe_topic(registration_tokens, topic_name)
    headers = {
      Authorization: "key=#{ENV['FCM_SERVER_KEY']}",
      'Content-Type' => 'application/json'
    }
    params = {
      to: "/topics/#{topic_name}",
      registration_tokens: registration_tokens
    }
    response = request('/iid/v1:batchRemove', headers, params.to_json, :post)

    case response.status
    when 200
      json = JSON.parse(response.body)
    when 401
      raise Exceptions::Unauthorized
    when 404
      raise Exceptions::NotFound
    else
      raise Exceptions::InternalServerError
    end

    json
  end
end
