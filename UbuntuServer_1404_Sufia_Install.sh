#!/usr/bin/env bash
set -o errexit

# 1. Update packages
cd ~
sudo apt-get update
sudo apt-get upgrade -y

# 2. Install rbenv and ruby-build
# You should have git to get this script.
git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
cd ~/.rbenv
git checkout v0.4.0
cd ~
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
cd ~/.rbenv/plugins/ruby-build
git checkout v20140702
cd ~
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# 3. Install Ruby
sudo apt-get install -y gcc make libssl-dev
rbenv install 2.1.2
rbenv global 2.1.2
rbenv rehash

# 4. Install Redis, ImageMagick, and Node.js
sudo apt-get install -y redis-server imagemagick nodejs

# 5. Install FITS
sudo apt-get install -y unzip
mkdir ~/fits/
cd ~/fits/
wget http://projects.iq.harvard.edu/files/fits/files/fits-0.8.0.zip
unzip ./fits-0.8.0.zip
sudo chmod a+x ~/fits/fits-0.8.0/fits.sh
cd ~/
echo 'export PATH="$HOME/fits/fits-0.8.0:$PATH"' >> ~/.bashrc
export PATH="$HOME/fits/fits-0.8.0:$PATH"

# 6. Install ffmpeg
sudo add-apt-repository -y ppa:jon-severinsson/ffmpeg
sudo apt-get update
sudo apt-get install -y ffmpeg

# 7. Install Rails
gem install --no-document rails --version 4.0.8
rbenv rehash
rails new vtw2
cd ~/vtw2/

# 8. Set up Sufia
sudo apt-get install -y libsqlite3-dev g++
echo "gem 'sufia', '3.7.2" >> ~/vtw2/Gemfile
echo "gem 'kaminari', github: 'harai/kaminari', branch: 'route_prefix_prototype'" >> ~/vtw2/Gemfile
echo "gem 'font-awesome-sass-rails'" >> ~/vtw2/Gemfile
bundle install
rbenv rehash
rails g sufia -f
rbenv rehash
rake db:migrate
sed 's/require_tree ./require sufia/' <~/vtw2/app/assets/stylesheets/application.css >~/vtw2/temp
mv ~/vtw2/temp ~/vtw2/app/assets/stylesheets/application.css
sed '/\/\/= require turbolinks/ d' <~/vtw2/app/assets/javascripts/application.js > ~/vtw2/temp
echo '//= require sufia' >> ~/vtw2/temp
mv ~/vtw2/temp ~/vtw2/app/assets/javascripts/application.js

# 9. Fix stylesheets.
gemdir=`gem environment gemdir`
gemdir="$gemdir/gems/sufia-3.7.2/app/assets/stylesheets"
sed -r "s/url\(<%= asset_path ('fonts.*') %>\)/asset_url(\1)/" \
<"$gemdir/applcation-bootstrap.css.erb" >~/vtw2/app/assets/stylesheets/application-bootstrap.css.erb
sed -r "s/url\(<%= asset_path ('vjs.*') %>\)/asset_url(\1)/" \
<"$gemdir/video-js.css.erb" >~/vtw2/app/assets/stylesheets/video-js.css.erb

# 10. Start Sufia server.
sudo apt-get install -y default-jre
QUEUE=* rake resque:work &
rake jetty:clean
rake jetty:config
rake jetty:start
rails s