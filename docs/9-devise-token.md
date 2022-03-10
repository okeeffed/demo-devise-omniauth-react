# Devise Part 9: Authenticating with a opaque tokens

## Adding to Rails repo

```s
# Add the gem
$ bundler add devise-jwt
```

Next step, we need to update our Devise initializer.

Update the `config/initializers/devise.rb` file to configure the `jwt` property:

```rb
Devise.setup do |config|
  # ...
  config.jwt do |jwt|
    jwt.secret = ENV['DEVISE_JWT_SECRET_KEY']
		jwt.request_formats = { api_user: [:json] }
  end
end
```

Inside of `.env` we need to add our `DEVISE_JWT_SECRET_KEY`. You should make this at least 128 random characters.

"The format of incoming requests that devise-jwt should pay attention to. In my app, I only want JSON web tokens to be issued for JSON requests (you could also add nilto the array, which means unspecified format). For HTML requests, I want users to go to the web interface at a different endpoint, “/signin”, so if someone visits /api/login with an HTML request instead of JSON, I want devise-jwt to ignore it."

We can generate a value with `bundle exec rake secret` to use for this.

```s
$ bundler exec rake secret
# Example output:
# 0a9884c69756b8d2ce253f027fc37be00b30da2949a505ee22c5c1ed6ab2f77c417e7980bc6757fb8d1e0fd6f3dd221931c2e61bd31cb457d840916634be8309
```

## Update the User model

Inside of `app/models/user.rb`:

```rb
class User < ApplicationRecord
  enum user_type: {
    basic: 0,
    admin: 1
  }
  has_and_belongs_to_many :documents

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :omniauthable,
         :jwt_authenticatable, omniauth_providers: ['github'],
                               jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      # user.name = auth.info.name   # assuming the user model has a name
      # user.image = auth.info.image # assuming the user model has an image
      # If you are using confirmable and the provider(s) you use validate emails,
      # uncomment the line below to skip the confirmation emails.
      # user.skip_confirmation!
    end
  end
end
```

It is really important to note that we are using the [null revocation strategy](https://github.com/waiting-for-dev/devise-jwt#revocation-strategies).

It is strongly recommended that you don't use this if you need to revoke tokens (which you very likely will).

For now, I will leave token revocation out-of-scope, but you can follow that link about to read and implement the other strategies. Most just require some more configuration around your models.

## Update the CORS configuration

```rb
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
             methods: %i[get post put patch delete options head]
  end
end
```

Note: The order of the resource is important.

## Updating our session storage

There are some [caveats](https://github.com/waiting-for-dev/devise-jwt#session-storage-caveat) around session storage.

We are going to keep things simple here. Since we still want session storage for the frontend app, we will update our devise configuration to skip session storage.

Update the `config/initializers/devise.rb` file for this:

```rb
Devise.setup do |config|
  # ...
  config.skip_session_storage = [:http_auth, :params_auth]
end
```

## Making adjustments to our previous code

In an earlier part, we were using CSRF tokens with our separate frontend. Let's remove that so that we only rely on our JWT token.

Update `app/controllers/application_controller.rb`:

```rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
end
```

Update `config/routes.rb`:

```rb
Rails.application.routes.draw do
  devise_for :users,
             controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'users/sessions',
                            registrations: 'users/registrations' }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  namespace :api do
    namespace :v1 do
      resources :documents, only: %i[index create update destroy]
    end
  end

  # Defines the root path route ("/")
  resources :users
  resources :home, only: %i[index create]
  root 'home#index'
end
```

You can also delete the `app/controllers/session_controller.rb` file as we are no longer using it.

## Updating our remote app

In `<your-nextjs-frontend>/pages/_app.tsx`, we need to remove the calls to `http://localhost:3000/session`:

```tsx
import "../styles/globals.css";
import type { AppProps } from "next/app";

function MyApp({ Component, pageProps }: AppProps) {
  return <Component {...pageProps} />;
}

export default MyApp;
```

We next need to update our sign in and test endpoint functions to set and get the `Authorization` header.

For `remote-app/pages/index.tsx`

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

    const { headers } = await axios.post(
      "http://localhost:3000/users/sign_in",
      {
        user: {
          email: target.email.value,
          password: target.password.value,
          remember_me: 0,
        },
      }
    );

    localStorage.setItem("token", headers["authorization"]);
  };

  const testEndpoint = async () => {
    try {
      const { data } = await axios.get("http://localhost:3000/api/v1/example", {
        headers: {
          "Content-Type": "application/json",
          Authorization: localStorage.getItem("token") ?? "",
        },
      });
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

For `remote-app/pages/another.tsx`:

```tsx
import type { NextPage } from "next";
import Head from "next/head";
import Link from "next/link";
import styles from "../styles/Home.module.css";
import axios from "../lib/axios";

const Home: NextPage = () => {
  const testEndpoint = async () => {
    try {
      const { data } = await axios.get("http://localhost:3000/api/v1/example", {
        headers: {
          "Content-Type": "application/json",
          Authorization: localStorage.getItem("token") ?? "",
        },
      });
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

export default Home;
```

Notice that we are now sending a test endpoint request to `/api/v1/example` now, so we need to set that up.

## Example controller

Create a new file `app/controllers/api/v1/example_controller.rb` and add the following:

```rb
class Api::V1::ExampleController < ApplicationController
  respond_to :json

  def index
    render json: { message: 'Hello World' }
  end
end
```

Enable that route in `config/routes.rb`:

```rb
Rails.application.routes.draw do
  devise_for :users,
             controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'users/sessions',
                            registrations: 'users/registrations' }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  namespace :api do
    namespace :v1 do
      resources :documents, only: %i[index create update destroy]
      resources :example, only: %i[index]
    end
  end

  # Defines the root path route ("/")
  resources :users
  resources :home, only: %i[index create]
  root 'home#index'
end
```

## Disabling reCAPTCHA

Our Next.js app is missing reCAPTCHA, so you can either add that in or disable reCAPTCHA in `app/controllers/users/sessions_controller.rb` and `app/controllers/users/registrations_controller.rb`.

I did this by commenting out the `prepend_before_action` hooks that we had.

You will also need to add `skip_forgery_protection, only: [:create]` to skip CSRF authentication on those controllers.

I also add a `respond_with` private method to send a JSON response.

The `app/controllers/users/sessions_controller.rb` now looks like so:

```rb
# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # prepend_before_action :check_captcha, only: [:create] # Change this to be any actions you want to protect.
  skip_forgery_protection

  private

  def check_captcha
    return if verify_recaptcha # verify_recaptcha(action: 'login') for v3

    self.resource = resource_class.new sign_in_params

    respond_with_navigational(resource) do
      flash.discard(:recaptcha_error) # We need to discard flash to avoid showing it on the next page reload
      render :new
    end
  end

  def respond_with(resource, _opts = {})
    render json: {
      status: { code: 200, message: 'Logged in sucessfully.' },
      data: resource.as_json(only: %i[id email name role created_at updated_at])
    }, status: :ok
  end
end
```

> Note: the `respond_with` method will break the login flow for the main React app (not the separate Next.js app).

## Running our app

Run `bin/dev` and ensure your Next.js remote app from an earlier[part four](https://blog.dennisokeeffe.com/blog/2022-03-07-part-4-authenticated-with-a-separate-frontend) is running.

I updated my `Procfile.dev` to also run the Next.js app. An example of my `Procfile.dev`:

```s
web: bin/rails server -p 3000
js: yarn build --watch
css: bin/rails tailwindcss:watch
nextjs: npm --prefix remote-app run dev
```
