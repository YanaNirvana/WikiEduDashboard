#!/usr/bin/env bash

clear

CLEAR_LINE='\r\033[K'
output_line()
{
  while read -r line
  do
      printf "${CLEAR_LINE}$line"
      echo $line >> setup/log.txt
  done < <($1)
}

echo 'Setting up your developmental environment. This may take a while.'

echo '[+] Creating log file...'
touch setup/log.txt
echo '[+] Log File created! \n'

printf '[*] Checking for Curl... \n'
if ! which curl >/dev/null; then
  printf "${CLEAR_LINE}Curl Not Found! \n"
  printf '[*] Installing Curl... \n'
  output_line "sudo apt-get install -y curl" && printf "${CLEAR_LINE}[+] Curl installed!"
else
  printf "${CLEAR_LINE}Curl Found! \n"
fi

printf '[*] Adding keys... \n'

# Add keys for Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
output_line "echo \"deb https://dl.yarnpkg.com/debian/ stable main\" | sudo tee /etc/apt/sources.list.d/yarn.list"

# Add Keys for MariaDB
output_line "sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8" && \
output_line "sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirror.jmu.edu/pub/mariadb/repo/10.1/ubuntu xenial main'"
printf "${CLEAR_LINE}[+] Added keys for required repositries! \n"

printf '[*] Updating Package lists... \n'
output_line "sudo apt-get update" && printf "${CLEAR_LINE}[+] Updated Package lists! \n"

printf '[*] Installing R... \n'
output_line "sudo apt install -y r-base" && printf "${CLEAR_LINE}[+] R installed! \n"

printf '[*] Installing node.js... \n'
if which node | grep node >/dev/null;then
  printf "${CLEAR_LINE}Node already installed! \n"
else
  output_line "curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - && sudo apt-get install -y nodejs" &&\
  printf "${CLEAR_LINE}[+] Node installed! \n"
fi

printf '[*] Installing GNUpg... \n'
output_line "sudo apt-get install -y gnupg" && printf "${CLEAR_LINE}[+] GNUpg installed! \n"

printf '[*] Installing yarn... \n'
output_line "sudo apt-get install -y yarn" && printf "${CLEAR_LINE}[+] Yarn installed! \n"

printf '[*] Installing pandoc... \n'
output_line "sudo apt-get install -y pandoc" && printf "${CLEAR_LINE}[+] Pandoc installed! \n"

printf '[*] Installing redis-server... \n'
output_line "sudo apt install -y redis-server" && printf "${CLEAR_LINE}[+] Redis-Server installed! \n"

printf '[*] Installing mariadbclient dependencies... \n'
output_line "sudo apt-get install -y libmariadbclient-dev" && printf "${CLEAR_LINE}[+] Dependencies installed! \n"

printf '[*] Installing MariaDB-server... \n'
output_line "sudo apt-get install -y software-properties-common"
output_line "sudo apt-get install -y mariadb-server" && printf "${CLEAR_LINE}[+] MariaDB installed!"
output_line "sudo systemctl start mariadb.service" && \
output_line "sudo systemctl enable mariadb.service" && \
printf "${CLEAR_LINE}MariaDB service started! \n"

printf '[*] Checking for rvm... \n'
if ! which rvm > /dev/null; then
  output_line "gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB" && printf "${CLEAR_LINE}[*] Installing rvm... \n" && \
  output_line "\curl -sSL https://get.rvm.io | bash -s stable" && \
  printf "${CLEAR_LINE}[+] RVM installed! \n"
  source ~/.rvm/scripts/rvm
else
  printf "${CLEAR_LINE}RVM already installed! \n"
fi

printf '[*] Installing Ruby-2.5.0... \n'
output_line "rvm install ruby-2.5.0" && printf "${CLEAR_LINE}[+] Ruby-2.5.0 installed! \n"

printf '[*] Installing bundler... \n'
output_line "gem install bundler" && printf "${CLEAR_LINE}[+] Bundler installed! \n"

printf '[*] Installing Gems... \n'
output_line "bundle install" && printf "${CLEAR_LINE}[+] Gems installed! \n"

printf '[*] Installing phantomjs-prebuilt... \n'
output_line "sudo yarn global add phantomjs-prebuilt" && printf "${CLEAR_LINE}[+] phantomjs-prebuilt installed! \n"

printf '[*] Installing bower... \n'
output_line "sudo yarn global add bower" && printf "${CLEAR_LINE}[+] bower installed! \n"

printf '[*] Checking for application configurations... \n'
if [ -f config/application.yml ]; then
  printf "${CLEAR_LINE}Application configurations found! \n"
else
  printf "${CLEAR_LINE}Application configurations not found! \n"
  printf '[*] Creating Application configurations... \n'
  cp config/application.example.yml config/application.yml && printf "${CLEAR_LINE}Application configurations created! \n"
fi

printf "[*] Creating Databases... \n"
echo "CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      exit" | sudo mysql -p && printf "${CLEAR_LINE}[+] Databases created! \n"

printf '[*] Checking for Database configurations... \n'
if [ -f config/database.yml ]; then
  printf "${CLEAR_LINE}Database configurations found! \n"
  echo 'You would need to connect the database for your configured user!'
  echo 'After connecting your database kindly run migrations with'
  echo '"rake db:migrate"'
  echo '"rake db:migrate RAILS_ENV=test"'
else
  printf "${CLEAR_LINE}Database configurations not found! \n"
  printf '[*] Creating Database configurations... \n'
  cp config/database.example.yml config/database.yml
  printf "${CLEAR_LINE}Database configurations created! \n"

  printf '[*] Creating User for Mysql... \n'
  echo "CREATE USER 'wiki'@'localhost' IDENTIFIED BY 'wikiedu';
      GRANT ALL PRIVILEGES ON dashboard . * TO 'wiki'@'localhost';
      GRANT ALL PRIVILEGES ON dashboard_testing . * TO 'wiki'@'localhost';
      exit" | sudo mysql -p > /dev/null && printf "${CLEAR_LINE}[+] User created! \n" && \
      printf '[*] Migrating databases... \n'
      output_line "rake db:migrate" && \
      output_line "rake db:migrate RAILS_ENV=test"  && \
      printf "${CLEAR_LINE}[+] Database migration completed! \n"
fi

printf '[*] Installing node_modules... \n'
output_line "yarn" && printf "${CLEAR_LINE}[+] node_modules installed! \n"

printf '[*] Installing bower modules... \n'
output_line "bower install" && printf "${CLEAR_LINE}[+] bower modules installed! \n"

printf '[*] Installing gulp... \n'
output_line "sudo yarn global add gulp" && printf "${CLEAR_LINE}[+] Gulp installed! \n"

echo 'Your developmental environment setup is completed! If you have any errors try to refer to the docs for manual installation or ask for help!'
