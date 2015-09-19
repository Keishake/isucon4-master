#! /env/ruby
require 'mysql2-cs-bind'
require 'redis'
redis = Redis.new host:"127.0.0.1", port: "6379"
db = Mysql2::Client.new(
          host: ENV['ISU4_DB_HOST'] || 'localhost',
          port: ENV['ISU4_DB_PORT'] ? ENV['ISU4_DB_PORT'].to_i : nil,
          username: ENV['ISU4_DB_USER'] || 'root',
          password: ENV['ISU4_DB_PASSWORD'],
          database: ENV['ISU4_DB_NAME'] || 'isu4_qualifier',
          reconnect: true,
        )

users = db.xquery('SELECT * FROM users')
users.each do |u|
  login = u["login"]
  data = db.xquery('SELECT ip,created_at FROM login_log WHERE succeeded = 1 AND user_id = ? ORDER BY id DESC LIMIT 2', u['id']).each
  if data.count >=2
    last_data = data.last
    data = data.first
    redis.set "#{login}_ip_prev", last_data["ip"]
    redis.set "#{login}_time_prev", last_data["created_at"].to_i
    redis.set "#{login}_ip", data["ip"]
    redis.set "#{login}_time", data["created_at"].to_i
  end
  if data.count == 1
    data = data.first
    redis.set "#{login}_ip", data["ip"]
    redis.set "#{login}_time", data["created_at"].to_i
  end

end
