#!/bin/bash

echo -e "Databases will be created with app name prefixed (app-name_production & app-name_staging)"
echo -e "Please enter app name [default rails-app]: "
read APP_NAME || APP_NAME=rails-app
echo -e "Please enter app domain [default example.com]: "
read APP_DOMAIN || APP_DOMAIN=example.com
# echo -e "Please enter a secret key, generate it with 'rake secret' in your local machine: "
# read APP_SECRET_KEY || APP_SECRET_KEY="0e37b086b9cb86cb9bee85228ed631bc55c76292adfc005adafa659574e1856d6e45dd4f224bee0e53473c072f31700f644484a91e35ca2baf120b280f115e90"


PRODUCTION_DB_NAME=$APP_NAME"_production"
STAGING_DB_NAME=$APP_NAME"_staging"

sudo sed -i -e '/^Port/s/^.*$/Port 22/' /etc/ssh/sshd_config
# sudo sed -i -e '/^PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i -e '$aAllowUsers deploy' /etc/ssh/sshd_config
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo add-apt-repository ppa:chris-lea/redis-server
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger focal main > /etc/apt/sources.list.d/passenger.list'
sudo apt-get update
sudo apt-get install -y libpq-dev postgresql postgresql-contrib
sudo apt-get install -y git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev dirmngr gnupg apt-transport-https ca-certificates redis-server redis-tools nodejs yarn
sudo apt-get install -y nginx-extras libnginx-mod-http-passenger
sudo apt-get install -y imagemagick libvips
if [ ! -f /etc/nginx/modules-enabled/50-mod-http-passenger.conf ]; then sudo ln -s /usr/share/nginx/modules-available/mod-http-passenger.load /etc/nginx/modules-enabled/50-mod-http-passenger.conf ; fi
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
git clone https://github.com/rbenv/rbenv-vars.git ~/.rbenv/plugins/rbenv-vars
source ~/.bashrc
rbenv install 3.1.2
rbenv global 3.1.2
echo "gem: --no-document" > ~/.gemrc
gem install bundler
rbenv rehash
sudo sed -i -e 's|/usr/bin/passenger_free_ruby|/home/deploy/.rbenv/shims/ruby|' /etc/nginx/conf.d/mod-http-passenger.conf
sudo rm /etc/nginx/sites-enabled/default
sudo -u postgres createuser deploy
sudo -u postgres createdb -O deploy $PRODUCTION_DB_NAME
sudo -u postgres createdb -O deploy $STAGING_DB_NAME
sudo touch /etc/nginx/sites-enabled/$APP_NAME
sudo dd of=/etc/nginx/sites-enabled/$APP_NAME << EOF
server {
        listen 80;
        listen [::]:80 ipv6only=on;

        server_name $APP_DOMAIN;
        passenger_enabled on;
        passenger_app_env production;
        root         /home/deploy/$APP_NAME/current/public;

        location /cable {
            passenger_app_group_name $APP_NAME-websocket;
            passenger_force_max_concurrent_requests_per_process 0;
        }

        client_max_body_size 100m;

        location ~ ^/(assets|packs) {
          expires max;
          gzip_static on;
        }
}
EOF
mkdir -p /home/deploy/$APP_NAME/shared/config
cat > /home/deploy/$APP_NAME/shared/config/database.yml <<EOF
production:
  adapter: postgresql
  database: $PRODUCTION_DB_NAME
  encoding: unicode
  pool: 5
staging:
  adapter: postgresql
  database: $STAGING_DB_NAME
  encoding: unicode
  pool: 5  
EOF
# cat > /home/deploy/$APP_NAME/shared/config/secrets.yml <<EOF
# production:
#   secret_key_base: $APP_SECRET_KEY
# EOF
# cat > /home/deploy/$APP_NAME/shared/config/application.yml <<EOF
# FACEBOOK_APP_ID: "571848349826089"
# FACEBOOK_APP_SECRET: "cfab80a7e0b4e88aa65dae9fe2052f70"
# EOF
sudo service nginx restart
echo -e "DONE, YOU CAN DEPLOY YOUR RAILS APPLICATION NOW"