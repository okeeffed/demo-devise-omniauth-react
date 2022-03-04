# README

This will follow along with the in-depth [blog post](https://blog.dennisokeeffe.com)

Aims:

- [x] Use Devise
- [x] Setup auth for users
- [ ] Add a React Native app and setup auth
- [ ] Add in GitHub OAuth example

## Part 1: Setting up devise

```s
# Create a new app
$ rails new demo-devise-omniauth-react -j esbuild
$ cd demo-devise-omniauth-react

# Add required gem
$ bundler add devise

# Scaffold the app
$ bin/rails generate devise:install
$ bin/rails generate devise User

# Generate a home controller for us to test against
$ bin/rails generate controller home index
```

Update the dev config at `config/environments/development.rb`:

```s
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
```

Update the application controller at `app/controllers/application_controller.rb` to always require auth:

```rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
end
```

Update our routes to set our Home controller index to the root route:

```rb
Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'home#index'
end
```

In my current version of Rails 7, I also needed to update the `config/initializers/devise.rb` file to uncomment the `config.navigational_formats` and add the `:turbo_stream` for the default Devise handler after signing up:

```rb
config.navigational_formats = ['*/*', :html, :turbo_stream]
```

We won't setup the React app in part one, so for now let's set the values of `app/views/home/index.html.erb` to the following:

```html
<h1>Home#index</h1>
<p>Find me in app/views/home/index.html.erb</p>
<%= link_to "Log out", destroy_user_session_path, data: { "turbo-method":
:delete } %>
```

Finally, we can migrate and start the server:

```s
# Create and migrate the db
$ bin/rails db:create db:migrate

# Start the server (including the React app)
$ bin/dev
```

At this stage, going to `localhost:3000` will redirect us to login or signup.

Sign up for the app and you will see us log in.

At this stage, you will be redirected to the home page successfully. If you click the `Log out` button at the bottom, you will be redirected to login.

### Things to note for Part 1

If you check under `db/migrate/<timestamp>_devise_create_users.rb` for the Devise migration, you will see we also had some options to uncomment some strings to help us set up the `Trackable`, `Confirmable` and `Lockable` options.

Those options could have been added under the `app/models/user.rb` file. We will touch back on OmniAuth later for another part.

## Part 2: Changing from a Cookie store to using Redis for a session store

Add `rack-cors` gem.

Update the application controller:

```rb
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :set_csrf_cookie
  before_action :authenticate_user!

  private

  def set_csrf_cookie
    cookies['CSRF-TOKEN'] = form_authenticity_token
  end
end
```

Create file for CORS init:

```rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:3000', 'localhost:4000'

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true
  end
end
```

Create file for session store init:

```rb
Rails.application.config.session_store :redis_store,
                                       servers: ['redis://localhost:6379/0/session'],
                                       expire_after: 90.minutes,
                                       key: '_demo_devise_omniauth_react_session'
```

Update `config/application.rb`:

```rb
require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DemoDeviseOmniauthReact
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Since we will be using other origins
    config.action_controller.forgery_protection_origin_check = false
  end
end
```

That setup will get you ready to be able to enable you to have more capability over ending sessions.

## Part 3: Adding in another Next.js frontend that uses the monolith as an API

```s
# Create a new Next.js application
$ npx create-next-app@latest --ts another-frontend
$ cd another-frontend

$ mkdir lib
$ touch pages/another.tsx lib/axios.ts
```

To enable us to use session cookies for API auth in the React Native app, we can follow a similar path to a [blog post](https://pragmaticstudio.com/tutorials/rails-session-cookies-for-api-authentication) written by Pragmatic Studio.

```ts
import axios from "axios";

axios.defaults.xsrfCookieName = "CSRF-TOKEN";
axios.defaults.xsrfHeaderName = "X-CSRF-Token";
axios.defaults.withCredentials = true;

export default axios;
```
