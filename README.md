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

Notes:

Add `rack-cors` gem.

Start up the app with `bin/dev`.

In another terminal, you can see what is happening with `redis-cli monitor`.

You will get something like this:

```s
$ redis-cli monitor
OK
1646385148.623807 [0 [::1]:49436] "get" "session:2::69618aacfcd4737514bd0d540b73ccc2020b5f98a192c2baa38fda2c7618f8e0"
1646385148.880797 [0 [::1]:49436] "del" "session:2612c5dbfddbd05a599133f36b8aef68"
1646385148.883186 [0 [::1]:49436] "del" "session:2::69618aacfcd4737514bd0d540b73ccc2020b5f98a192c2baa38fda2c7618f8e0"
1646385148.884397 [0 [::1]:49436] "setex" "session:2::ecb8e65b0cdda7092604b3b3b66873202cec32d1ca1af8f589eddfde63022cdb" "5400" "\x04\b{\aI\"\x19warden.user.user.key\x06:\x06ET[\a[\x06i\x06I\"\"$2a$12$OVcvnckKRbDKK5UEPZubl.\x06;\x00TI\"\nflash\x06;\x00T{\aI\"\x0cdiscard\x06;\x00T[\x00I\"\x0cflashes\x06;\x00T{\x06I\"\x0bnotice\x06;\x00FI\"\x1cSigned in successfully.\x06;\x00T"
1646385148.905098 [0 [::1]:49436] "get" "session:2::ecb8e65b0cdda7092604b3b3b66873202cec32d1ca1af8f589eddfde63022cdb"
1646385148.920525 [0 [::1]:49436] "setex" "session:2::ecb8e65b0cdda7092604b3b3b66873202cec32d1ca1af8f589eddfde63022cdb" "5400" "\x04\b{\bI\"\x19warden.user.user.key\x06:\x06ET[\a[\x06i\x06I\"\"$2a$12$OVcvnckKRbDKK5UEPZubl.\x06;\x00TI\"\nflash\x06;\x00T{\aI\"\x0cdiscard\x06;\x00T[\x00I\"\x0cflashes\x06;\x00T{\x06I\"\x0bnotice\x06;\x00FI\"\x1cSigned in successfully.\x06;\x00TI\"\x10_csrf_token\x06;\x00FI\"0vS4dc826i_YDuGX6PGKHyHCLQp7fsUw_KiXsMByvdMs\x06;\x00F"
```

If you reload the page you will still be signed in and you'll notice more requests are made to the `redis-cli monitor` terminal.

One of the benefits of Redis session storage is that you have full control over the session. If you run `redis-cli flushdb` in another terminal and then reload the page, you'll notice that the session has been removed and you'll be redirected to log in once again.

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

## Part 4: Custom styles on the home page

```s
# Add and install tailwind
$ bundler add tailwindcss-rails
$ bin/rails tailwindcss:install
```

We want to add some custom Devise styles, so let's use the generator helper:

```s
# Generate devise views
$ rails generate devise:views
```

Update `app/views/devise/sessions/new.html.erb` to start making some nicer styles:

```rb
<h2>Edit <%= resource_name.to_s.humanize %></h2>

<%= form_for(resource, as: resource_name, url: registration_path(resource_name), html: { method: :put }) do |f| %>
  <%= render "devise/shared/error_messages", resource: resource %>

  <div class="field">
    <%= f.label :email %><br />
    <%= f.email_field :email, autofocus: true, autocomplete: "email" %>
  </div>

  <% if devise_mapping.confirmable? && resource.pending_reconfirmation? %>
    <div>Currently waiting confirmation for: <%= resource.unconfirmed_email %></div>
  <% end %>

  <div class="field">
    <%= f.label :password %> <i>(leave blank if you don't want to change it)</i><br />
    <%= f.password_field :password, autocomplete: "new-password" %>
    <% if @minimum_password_length %>
      <br />
      <em><%= @minimum_password_length %> characters minimum</em>
    <% end %>
  </div>

  <div class="field">
    <%= f.label :password_confirmation %><br />
    <%= f.password_field :password_confirmation, autocomplete: "new-password" %>
  </div>

  <div class="field">
    <%= f.label :current_password %> <i>(we need your current password to confirm your changes)</i><br />
    <%= f.password_field :current_password, autocomplete: "current-password" %>
  </div>

  <div class="actions">
    <%= f.submit "Update" %>
  </div>
<% end %>

<h3>Cancel my account</h3>

<p>Unhappy? <%= button_to "Cancel my account", registration_path(resource_name), data: { confirm: "Are you sure?" }, method: :delete %></p>

<%= link_to "Back", :back %>
```
