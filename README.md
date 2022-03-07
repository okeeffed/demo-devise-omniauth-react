# README

This will follow along with the in-depth [blog post](https://blog.dennisokeeffe.com)

Aims:

- [x] Use Devise
- [x] Setup auth for users
- [x] Using Redis session store instead of a cookie store
- [x] Add a another frontend and setup auth
- [x] Add in GitHub OAuth example

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

Second, we need to ensure that we have an endpoint to set the `CSRF-TOKEN` from Rails.

This might need some adjusting in your own work.

In `app/controllers/application_controller.rb`:

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

I also created a session controller that skipped the `authenticate_user!` action so that I could grab a token when I booted up the Next.js page.

I setup two pages in the Next.js app:

1. `remote-app/pages/index.tsx`
2. `remote-app/pages/another.tsx`

In `remote-app/pages/index.tsx`, set the following:

```tsx
import type { NextPage } from "next";
import Head from "next/head";
import Link from "next/link";
import styles from "../styles/Home.module.css";
import axios from "../lib/axios";
import * as React from "react";

const Home: NextPage = () => {
  const onSubmit = async (e: React.SyntheticEvent) => {
    e.preventDefault();
    console.log("submit");

    const target = e.target as typeof e.target & {
      email: { value: string };
      password: { value: string };
    };

    const { data } = await axios.post("http://localhost:3000/users/sign_in", {
      user: {
        email: target.email.value,
        password: target.password.value,
        remember_me: 0,
      },
    });

    console.log(data);
  };

  const testEndpoint = async () => {
    try {
      const { data } = await axios.post("http://localhost:3000/home");
      console.log(data);
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <div className={styles.container}>
      <Head>
        <title>Create Next App</title>
        <meta name="description" content="Generated by create next app" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className={styles.main}>
        <form onSubmit={onSubmit}>
          <div>
            <input name="email" type="text" placeholder="Email" />
          </div>
          <div>
            <input name="password" type="password" placeholder="Password" />
          </div>
          <div>
            <button type="submit">Sign in</button>
          </div>
        </form>
        <button onClick={testEndpoint}>Test Endpoint</button>

        <Link href="/another">Go to /another</Link>
      </main>
    </div>
  );
};

export default Home;
```

In `remote-app/pages/another.tsx`:

```tsx
import type { NextPage } from "next";
import Head from "next/head";
import Link from "next/link";
import styles from "../styles/Home.module.css";
import axios from "../lib/axios";

const Another: NextPage = () => {
  const testEndpoint = async () => {
    try {
      const { data } = await axios.post("http://localhost:3000/home");
      console.log(data);
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <div className={styles.container}>
      <Head>
        <title>Create Next App</title>
        <meta name="description" content="Generated by create next app" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className={styles.main}>
        <button onClick={testEndpoint}>Test Endpoint</button>
        <Link href="/">Go to home page</Link>
      </main>
    </div>
  );
};

export default Another;
```

> Note: The Next.js setup is very rough, so there is no redirecting if you are not logged in, etc. going on. You may want to implement that yourself.

I also updated `remote-app/pages/_app.tsx` to grab the initial token on a page change.

```tsx
import "../styles/globals.css";
import type { AppProps } from "next/app";
import { useEffect } from "react";
import { useRouter } from "next/router";
import axios from "../lib/axios";

function MyApp({ Component, pageProps }: AppProps) {
  const router = useRouter();

  useEffect(() => {
    axios.get("http://localhost:3000/session");
  }, [router.asPath]);

  return <Component {...pageProps} />;
}

export default MyApp;
```

Again, there may be a better way to work with this; this was my initial attempt at getting it all working.

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

## Part 5: OAuth with Devise and GitHub

At this stage, we are now going to add in GitHub OAuth login using Omniauth.

It is required that you have a GitHub app setup for this.

Head to your [GitHub developer settings](https://github.com/settings/developers) and create a new OAuth app.

After you have created it, make sure to copy down the Client ID and Client secret. We will need to add that to our Rails app environment.

Down around line 274 of the `config/initializers/devise.rb` file, we can uncomment the line `config.omniauth :github, 'APP_ID', 'APP_SECRET', scope: 'user,public_repo'` and update it to `config.omniauth :github, ENV.fetch('GITHUB_APP_ID'), ENV.fetch('GITHUB_APP_SECRET'), scope: 'user:email'`.

We need to add some required gems with bundler and then setup a migration for Omniauth. There are more notes on the GitHub OAuth [here](https://github.com/omniauth/omniauth-github).

```s
# Add required Gems
$ bundler add dotenv-rails --group "development,test"
$ bundler add omniauth-github
$ bundler add omniauth-rails_csrf_protection

# Adding in the Omniauth migration
# @see https://github.com/heartcombo/devise/wiki/OmniAuth:-Overview
$ bin/rails g migration AddOmniauthToUsers provider:string uid:string
$ bin/rails db:migrate
```

First, let's update the `config/application.rb` to make use of `dotenv-rails`:

```rb
require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Dotenv::Railtie.load

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

At this stage, you also need to update the `app/models/user.rb` class:

```rb
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable, omniauth_providers: %i[github]
end
```

Let's add in an un-styled link for logging in with GitHub at `app/views/devise/sessions/new.html.erb`:

```erb
<div class="min-h-full flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
  <div class="max-w-md w-full space-y-8">
    <div>
      <img class="mx-auto h-12 w-auto" src="https://tailwindui.com/img/logos/workflow-mark-indigo-600.svg" alt="Workflow">
      <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">Sign in to your account</h2>
      <%- if devise_mapping.registerable? && controller_name != 'registrations' %>
        <p class="mt-2 text-center text-sm text-gray-600">
          Or
          <%= link_to "sign up", new_registration_path(resource_name), class: "font-medium text-indigo-600 hover:text-indigo-500" %>
        </p>
      <% end %>
    </div>
    <%= form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>
      <div class="mt-8 space-y-6">
        <input type="hidden" name="remember" value="true">
        <div class="rounded-md shadow-sm -space-y-px">
          <div>
            <%= f.label :email, class: "sr-only", for: "email-address" %>
            <%= f.email_field :email, id: "email-address", autofocus: true, autocomplete: "email", placeholder: "Email address", class: "appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm" %>
          </div>
          <div>
            <%= f.label :password, for: "password", class: "sr-only" %>
            <%= f.password_field :password, id: "password", autocomplete: "current-password", placeholder: "Password", class: "appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm" %>
          </div>
        </div>
        <% if devise_mapping.rememberable? %>
          <div class="flex items-center justify-between">
            <div class="field flex items-center">
              <%= f.check_box :remember_me, class: "h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded" %>
              <%= f.label :remember_me, class: "ml-2 block text-sm text-gray-900" %>
            </div>
            <div class="text-sm">
              <%- if devise_mapping.recoverable? && controller_name != 'passwords' && controller_name != 'registrations' %>
                <%= link_to "Forgot your password?", new_password_path(resource_name), class: "font-medium text-indigo-600 hover:text-indigo-500" %>
              <% end %>
            </div>
          </div>
        <% end %>
        <div class="actions">
          <%= f.submit "Log in", class: "actions group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500" %>
        </div>
      </div>
    <% end %>
    <%- if devise_mapping.omniauthable? %>
      <%- resource_class.omniauth_providers.each do |provider| %>
        <%= button_to "Sign in with #{OmniAuth::Utils.camelize(provider)}", omniauth_authorize_path(resource_name, provider), method: :post, "data-turbo": false %>
      <% end %>
    <% end %>
  </div>
</div>
```

The `if devise_mapping.omniauthable?` block is what was added as a helper.

Next, in `config/routes.rb` let's update the line `devise_for :users` to `devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }`.

Under `app/controllers/users/omniauth_callbacks_controller.rb` we add the following:

```rb
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
  skip_before_action :verify_authenticity_token, only: :github

  def github
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
      set_flash_message(:notice, :success, kind: "Github") if is_navigational_format?
    else
      session["devise.github_data"] = request.env["omniauth.auth"].except(:extra) # Removing extra as it can overflow some session stores
      redirect_to new_user_registration_url
    end
  end

  def failure
    redirect_to root_path
  end
end
```

The in `app/models/user.rb`:

```rb
def self.from_omniauth(auth)
  where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
    user.email = auth.info.email
    user.password = Devise.friendly_token[0, 20]
  end
end
```

At this stage, we can use `bin/dev` to start up our server and attempt the login process.

## Part 6: Adding in Recaptcha

Some links that we want working here:

1. [ambethia/recaptcha](https://github.com/ambethia/recaptcha)
2. [Devise wiki for recaptcha](https://github.com/heartcombo/devise/wiki/How-To%3A-Use-Recaptcha-with-Devise)

First, we need to add the `recaptcha` gem.

In our case - we are just going to implement recaptcha v2 that has the "I'm not a robot" statement.

```s
# Add recaptcha gem
$ bundler add recaptcha
```

Update the Devise form to have the Recaptcha tags `app/views/devise/registrations/new.html.erb`:

```html
<h2>Sign up</h2>
<%= form_for(resource, as: resource_name, url: registration_path(resource_name),
html: { data: { turbo: false} }) do |f| %> <%= render
"devise/shared/error_messages", resource: resource %>
<div class="field">
  <%= f.label :email %><br />
  <%= f.email_field :email, autofocus: true, autocomplete: "email" %>
</div>
<div class="field">
  <%= f.label :password %> <% if @minimum_password_length %>
  <em>(<%= @minimum_password_length %> characters minimum)</em>
  <% end %><br />
  <%= f.password_field :password, autocomplete: "new-password" %>
</div>
<div class="field">
  <%= f.label :password_confirmation %><br />
  <%= f.password_field :password_confirmation, autocomplete: "new-password" %>
</div>
<div class="actions"><%= f.submit "Sign up" %></div>
<%= flash[:recaptcha_error] %> <%= recaptcha_tags %> <% end %> <%= render
"devise/shared/links" %>
```

Note that on line two we needed to update the form to turn turbo off with `<%= form_for(resource, as: resource_name, url: registration_path(resource_name), html: { data: { turbo: false} }) do |f| %>`.

We need to do a similar adjustment to our file at `app/views/devise/sessions/new.html.erb`:

```html
<div
  class="min-h-full flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8"
>
  <div class="max-w-md w-full space-y-8">
    <div>
      <img
        class="mx-auto h-12 w-auto"
        src="https://tailwindui.com/img/logos/workflow-mark-indigo-600.svg"
        alt="Workflow"
      />
      <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
        Sign in to your account
      </h2>
      <%- if devise_mapping.registerable? && controller_name != 'registrations'
      %>
      <p class="mt-2 text-center text-sm text-gray-600">
        Or <%= link_to "sign up", new_registration_path(resource_name), class:
        "font-medium text-indigo-600 hover:text-indigo-500" %>
      </p>
      <% end %>
    </div>
    <%= form_for(resource, as: resource_name, url: session_path(resource_name),
    html: { data: { turbo: false} }) do |f| %>
    <div class="mt-8 space-y-6">
      <input type="hidden" name="remember" value="true" />
      <div class="rounded-md shadow-sm -space-y-px">
        <div>
          <%= f.label :email, class: "sr-only", for: "email-address" %> <%=
          f.email_field :email, id: "email-address", autofocus: true,
          autocomplete: "email", placeholder: "Email address", class:
          "appearance-none rounded-none relative block w-full px-3 py-2 border
          border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md
          focus:outline-none focus:ring-indigo-500 focus:border-indigo-500
          focus:z-10 sm:text-sm" %>
        </div>
        <div>
          <%= f.label :password, for: "password", class: "sr-only" %> <%=
          f.password_field :password, id: "password", autocomplete:
          "current-password", placeholder: "Password", class: "appearance-none
          rounded-none relative block w-full px-3 py-2 border border-gray-300
          placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none
          focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
          %>
        </div>
      </div>
      <% if devise_mapping.rememberable? %>
      <div class="flex items-center justify-between">
        <div class="field flex items-center">
          <%= f.check_box :remember_me, class: "h-4 w-4 text-indigo-600
          focus:ring-indigo-500 border-gray-300 rounded" %> <%= f.label
          :remember_me, class: "ml-2 block text-sm text-gray-900" %>
        </div>
        <div class="text-sm">
          <%- if devise_mapping.recoverable? && controller_name != 'passwords'
          && controller_name != 'registrations' %> <%= link_to "Forgot your
          password?", new_password_path(resource_name), class: "font-medium
          text-indigo-600 hover:text-indigo-500" %> <% end %>
        </div>
      </div>
      <% end %>
      <div class="actions">
        <%= f.submit "Log in", class: "actions group relative w-full flex
        justify-center py-2 px-4 border border-transparent text-sm font-medium
        rounded-md text-white bg-indigo-600 hover:bg-indigo-700
        focus:outline-none focus:ring-2 focus:ring-offset-2
        focus:ring-indigo-500" %>
      </div>
      <%# ADD HERE %> <%= flash[:recaptcha_error] %> <%= recaptcha_tags %> <%#
      END %>
    </div>
    <% end %> <%- if devise_mapping.omniauthable? %> <%-
    resource_class.omniauth_providers.each do |provider| %> <%= button_to "Sign
    in with #{OmniAuth::Utils.camelize(provider)}",
    omniauth_authorize_path(resource_name, provider), method: :post,
    "data-turbo": false %> <% end %> <% end %>
  </div>
</div>
```

Next, we need to add some environment variables to our `.env` file.

We will use test keys as outlined [here](https://developers.google.com/recaptcha/docs/faq#id-like-to-run-automated-tests-with-recaptcha.-what-should-i-do)

```s
RECAPTCHA_SITE_KEY="6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI"
RECAPTCHA_SECRET_KEY="6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe"
```

Following on from the [Devise docs](https://github.com/heartcombo/devise/wiki/How-To%3A-Use-Recaptcha-with-Devise#add-recaptcha-verification-in-controllers), we can add reCAPTCHA in the registration page.

We need to generate our registrations and sessions controller for Devise at this point. In the console:

```s
$ bin/rails g devise:controllers users -c=registrations
      create  app/controllers/users/registrations_controller.rb
$ bin/rails g devise:controllers users -c=sessions
      create  app/controllers/users/sessions_controller.rb
```

We need to update our `config/routes.rb` file:

```rb
Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'users/sessions', registrations: 'users/registrations' }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  resources :users
  resources :home, only: %i[index create]
  resources :session, only: [:index]
  root 'home#index'
end
```

Then, we need to update the file `app/controllers/users/registrations_controller.rb`:

```rb
# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  prepend_before_action :check_captcha, only: [:create] # Change this to be any actions you want to protect.

  private

  def check_captcha
    return if verify_recaptcha # verify_recaptcha(action: 'signup') for v3

    self.resource = resource_class.new sign_up_params
    resource.validate # Look for any other validation errors besides reCAPTCHA
    set_minimum_password_length

    respond_with_navigational(resource) do
      flash.discard(:recaptcha_error) # We need to discard flash to avoid showing it on the next page reload
      render :new
    end
  end
end
```

Inside of the user sessions controller `app/controllers/users/sessions_controller.rb`, add the following:

```rb
# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  prepend_before_action :check_captcha, only: [:create] # Change this to be any actions you want to protect.

  private

  def check_captcha
    return if verify_recaptcha # verify_recaptcha(action: 'login') for v3

    self.resource = resource_class.new sign_in_params

    respond_with_navigational(resource) do
      flash.discard(:recaptcha_error) # We need to discard flash to avoid showing it on the next page reload
      render :new
    end
  end
end
```

The docs also take you through adding recaptcha for the password reset page, but we will skip that part for now.

At this point, we can boot the application back up with `bin/dev` and attempt to register a new user at `http://localhost:3000/users/sign_up`.

First, attempt to sign up a user without selecting Recaptcha and you will get a failure message:

![TODO]()

Signing up correctly will work as expected after clicking on the Recaptcha form.

Afterwards, you can also sign out and try it on the sign in form:

![TODO]()
