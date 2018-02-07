# rails-start-server
Configure your server to deploy a Rails app with Capistrano, Nginx, Redis and Postgresql databases with just one command.

# How does this works?

Just spin up a new server in DigitalOcean or any provider, add a new user named 'deploy', login with this user, clone this repository and run

`bash -i rails-start-server.sh`

The script will prompt you for an app-name, a domain and a secret key (generate it with `rake secret` in your local machine.

Then it will do these steps automatically:

- install all dependencies (Postgresql, Nginx, Passenger, Redis, rbenv, Ruby 2.5.0)
- create databases (It will create 2 databases based on the 'app-name' you provided, app-name_production and app-name_staging)
- configure Nginx to work with Passenger and and a new Nginx site to the domain you provided
- add database.yml and secrets.yml in /app-name/shared/config based on the databases and secrets created before

Now you can focus on configuring Capistrano and deploy to this server like demonstrated in this tutorial:

https://gorails.com/deploy/ubuntu/16.04

This script follows and basically automates all the server parts of that tutorial
