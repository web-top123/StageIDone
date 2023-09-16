# i done this

[![Circle CI](https://circleci.com/gh/idonethis/idt-two.svg?style=svg&circle-token=cbddfa55a5e67a5fa1fc5c4892d59fbc8cad65fd)](https://circleci.com/gh/idonethis/idt-two)
[![Code Climate](https://codeclimate.com/repos/5703aded100d1f73da00519c/badges/34e188a275368bcc9bcf/gpa.svg)](https://codeclimate.com/repos/5703aded100d1f73da00519c/feed)
[![Test Coverage](https://codeclimate.com/repos/5703aded100d1f73da00519c/badges/34e188a275368bcc9bcf/coverage.svg)](https://codeclimate.com/repos/5703aded100d1f73da00519c/coverage)
[![Issue Count](https://codeclimate.com/repos/5703aded100d1f73da00519c/badges/34e188a275368bcc9bcf/issue_count.svg)](https://codeclimate.com/repos/5703aded100d1f73da00519c/feed)

**Quick daily updates from your team members**

Always know what each of your team members is working on and has accomplished. Never be in the dark about what is (or is not) getting done.

# Table of Contents

* [Technical Architecture Summary](#technical-architecture-summary)
* [Development Setup](#development-setup)
  * [Ruby](#ruby)
  * [Redis](#redis)
  * [PostgreSQL](#postgresql)
  * [`.env` file](#env-file)
  * [Running the app](#running-the-app)
  * [Testing](#testing)
* [Production Setup](#production-setup)
  * [Heroku](#heroku)
    * [Configuration](#configuration)
    * [Add-ons](#add-ons)
  * [Database](#database)
  * [Other Services](#other-services)
    * [DNS](#dns)
    * [SSL Certificates](#ssl-certificates)
    * [Email](#email)
  * [Account Access](#account-access)
* [Continuous Integration & Deployment](#continuous-integration--deployment)
  * [Deployment Checklist](#deployment-checklist)
* [API and OAuth](#api-and-oauth)
* [More Documentation](#more-documentation)

# Technical Architecture Summary

* Ruby on Rails application with a (largely) monolithic approach.
* Sidekiq with Redis backend for background task processing
* Hosted on Heroku
  * Has two types of dynos, for the main web app and for the sidekiq workers
  * Periodically runs rake tasks to schedule jobs for email delivery
* Database is an AWS RDS instance running PostgreSQL 9.4
* Uses mailgun for sending and receiving Email

# Development Setup

The application has three fundamental software requirements for a development environment, [Ruby on Rails](http://guides.rubyonrails.org/getting_started.html), [Redis](http://redis.io/download) and [PostgreSQL](http://www.postgresql.org/download/).

An assumed prerequisite for the following instructions is that you have a Mac and have [Homebrew](http://brew.sh/) and [Git](https://git-scm.com/downloads) installed.

## Ruby
To install Ruby and Rails, it is recommended that you use [rbenv](https://github.com/rbenv/rbenv#homebrew-on-mac-os-x) to get the version of Ruby required by the project (which is defined in [Gemfile](Gemfile)). To install both `rbenv` and enabling the `rbenv install` command, run the following commands.

```
brew update
brew install rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
```

Then install Ruby using `rbenv` and set that to the global version.

```
rbenv install 2.3.0
rbenv global 2.3.0
```

Along with Ruby, Rubygems will be automatically installed, so now you can install `bundler`, which should take care of the rest of the ruby dependency installations.

```
gem install bundler
```

Clone this repo to a location of your choice and navigate to the root, where you can run the `bundle` command to install all Ruby dependencies.

## Redis

Use Homebrew to install Redis and follow the instructions to auto-start the redis server on computer start or via `launchctl`.

```
brew install redis
```

then for example:

```
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.redis.plist
```

If Redis is running correctly `redis-cli ping` should respond with a `PONG`.

## PostgreSQL

PostgreSQL can sometimes be complicated to configure correctly because it will assume different database owner roles depending on your environment.

The basics of it is the same as for Redis.

```
brew install postgresql
```

Follow the instructions to autostart PostgreSQL when your computer starts (running a command such as `launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist`).

Navigate to the project root director and run

```
bundle
bundle exec rake db:create
```

The first command will install all needed project dependencies, and the second should create your database with the correct owner privileges. If it does not, it's a PostgreSQL configuration problem, ask someone and they will likely have solved it already.

## `.env` file

It is best-practice in the Rails world to store all your sensitive configuration variables in environment variables. The project uses the `dotenv-rails` gem to manage environment variables from a file named `.env` in the root directory.

Also in the root directory is a file called `env.default` that should always hold an exact mirror of all the environment variables that the application uses, you can copy this file to a file called `.env` to initialize your own environment file. However, the value of the variables in that file will all be fake. Ask a coworker to have them securely send you their `.env` file. Note that not all variables (such as for sending email) need to have real values in a development environment.

## Running the app

Now that you have Ruby, Redis, PostgreSQL and your environment file set up. It's time to run the app!

Go to the root folder of the application and run the following commands, the first will migrate the database and the second will seed it with necessary initial data (if needed).

```
bundle exec rake db:migrate
bundle exec rake db:seed
```

The application uses `foreman` to run the application in order to more accurately simulate the Heroku environment. To start the application you simply run

```
bundle exec foreman start
```

This will run both the app server and the worker server in parallel. Navigate to [http://localhost:5000](http://localhost:5000) and you should see a successfully running application.

## Testing

The should always be a comprehensive test-suite for this application and it is recommended that you run it frequently during development. The most basic way to run all tests is to run

```
bundle exec rake test
```

However, if you want to continously run the tests on any change, the application is configured to work well with [Guard](https://github.com/guard/guard). Guard will be watching for changes and running the tests for you, it will also give you some live reload functionality through [guard-livereload](https://github.com/guard/guard-livereload). To start it, simply run

```
bundle exec guard
```

# Production Setup

The production environment was created with simplicity in mind and tries to minimize maintenance overhead as much as reasonable. If there is ever any question whether we should self-host or pay someone else for it, always fault on paying someone else.

## Heroku

The application is entirely hosted on Heroku. This is mainly for ease of deployment, but also because of the quite powerful library of add-ons to easily add ancilliary services such as logging and scheduling. There is no reason the application shouldn't be easily moved to any other hosting provider in the future.

### Configuration

All configuration is managed through the `heroku config` command from the Heroku CLI tools. The configuration variables set should mirror those in the `env.default` file, but obviously with different values.

### Add-ons

The application currently uses the following add-ons, with a short explanation

* **Heroku Redis** - Redis database provider, used for caching and as the worker backend
* **Heroku Scheduler** - Runs rake commands every 10 minutes to schedule jobs to be run by the workers
* **Deploy Hooks** - Sends a message to slack when a deploy is made
* **SSL** - To get an SSL endpoint we can use
* **Papertrail** - Logging addon to easily search and review logs

## Database

The database is hosted with [AWS RDS](https://aws.amazon.com/rds/). It provides us with a relatively cheap, very scalable and fault-tolerant solution.

The database is running PostgreSQL 9.4 on `db.m3.large` instances in a Multi-AZ configuration for redundancy, has encryption at rest, General Purpose SSD and saves point-in-time backups for 7 days. These configuration parameters can be changed at any time if need be (such as going to Provisioned IOPS for further performance).

The database does *not* run in a VPC and allows ingress from `0.0.0.0/0`, these are requirements to be able to access the database from Heroku.

## Other Services
### DNS

[dnsimple](https://dnsimple.com) is our DNS provider and there is no specific naming policy adhered to, use what you need to use.

### SSL Certificates

We originally ordered our wildcard certificates from [digicert](https://digicert.com) and they can be re-issued there. You can also ask someone to securely share the existing certificates with you.

### Email

We currently use [Mailgun](https://mailgun.com) to both send and receive Email, nothing special here, they can easily be swapped in or out for any other Email provider with those capabilities.

## Account Access

If you need access to any of the above mentioned services or accounts, we use Dashlane to share logins if the service does not provide an in-app feature for team management. You should already have a Dashlane account, so ask your coworkers to share what you need.

# Continuous Integration & Deployment

We use [CircleCI](https://circleci.com/) to manage both builds (running the tests) and deployment. Any commit to any branch will trigger a build to happen for that commit.

We follow the general git flow during development.

1. Start with a github issue on the top of the Ready column on https://waffle.io/idonethis/idt-two.
2. Move the issues to the In Progress column (or the add the tag) when you start actively working on it.
3. When you start working on something, create a feature branch starting with your initials and followed by the issue number and/or a brief explanation of what the feature is, e.g. `fo-55-fix-something`.
4. Create a PR to Master and have a developer review it. 
5. If feeback is requires changes move it to the Refactor column. 
6. Merge your feature branch into staging and have someone QA it on the [Staging App](https://idt-two-staging.herokuapp.com/). Move the issue to the QA column (or add a QA tag on github) and @mention the QA teammates so they can start the process.
7. When your PR has been given the thumbs up by development and QA it can be merged into Master (which will deploy it to production)

Any commit to the `staging` branch will be automatically built and (if build is successful) deployed to the staging app that can be found on [https://idt-two-staging.herokuapp.com](https://idt-two-staging.herokuapp.com).

Any commit to the `master` branch will be automatically built and (if build is successful) deployed to the production app that can be found on [https://beta.idonethis.com](https://beta.idonethis.com).

CircleCI will run a build and, if successful, deploy. It will migrate the database for you, so you don't have to think about that. There is however a checklist below that you should mentally tick off everything in before you merge that PR into production.

Often you want to reset staging to master to match production before you merge your feature branch, just communicate with the dev and QA teams before proceeding.

**If you ever run into any problem with a deploy, please either fix the core problem forever, or add an item to the checklist below!**

## Deployment Checklist

* [ ] Did you write tests for your new feature?
* [ ] Did you run `bundle` and include the generated `Gemfile.lock`?

### If you added an environment variable

* [ ] Does the `circle.yml` file contain all necessary environment variables for running tests successfully?
* [ ] Have you updated the `env.default` file?
* [ ] Have you added the correct staging variable to the staging app?
* [ ] Have you added the correct production variable to the production app?

### If you added any new external dependencies

* [ ] Did you add the appropriate add-on to both the staging and production Heroku apps to service this new dependency?

# API and OAuth

Prior to July, 2016, there was a legacy API at [https://idonethis.com/api/v0.1/](https://cl.ly/342z272E1v3Q). This API was deprecated and an APIv2 was launched at [https://beta.idonethis.com/api/v2](https://beta.idonethis.com/api/v2). End user documentation is at [https://i-done-this.readme.io/docs](https://i-done-this.readme.io/docs).

We use [Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper) for providing OAuth2 access to the API. To add a new API consumer, access Doorkeeper's default [oauth/applications](https://beta.idonethis.com/oauth/applications) route as an admin (access is restricted to add new clients via [config/initializers/doorkeeper.rb#L17](https://github.com/idonethis/idt-two/blob/master/config/initializers/doorkeeper.rb#L17)). Doorkeeper makes many [other helpful routes](https://github.com/doorkeeper-gem/doorkeeper#routes).

To use the API, start by creating an application and getting the client id and secret id. Then using [the oauth2 gem](https://github.com/intridea/oauth2) create a client object. This client object ultimately creates a URL that the user needs to approve access to their iDoneThis account via. This approval returns a token which can then be used to make CRUD requests to the actual API. See [the iDoneThis CLI](https://github.com/idonethis/idonethis-cli) for a working example.

# Integrations

We provide various integrations, and the architecture for enabling integration is [here](docs/integration_infrastructure.md).

## Slack

To setup idt slack in local environment, refer to [this](docs/slack_app_setup.md).

# More Documentation

There is unfortunately no more documentation at this time. When there is, please update this readme to link to useful entry-points to various topics.
