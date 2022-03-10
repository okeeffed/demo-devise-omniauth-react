Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:3000', 'localhost:4000'

    resource '/users/sign_in',
             headers: %w[Authorization],
             methods: :any,
             expose: %w[Authorization],
             max_age: 600
    resource '/users/sign_up',
             headers: %w[Authorization],
             methods: :any,
             expose: %w[Authorization],
             max_age: 600
    resource '/api/*',
             headers: %w[Authorization],
             methods: :any,
             max_age: 600
    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true
  end
end
