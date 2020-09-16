# shopw5-dev-env

Development Environment on macos with Homestead for Shopware 5.5.x

## Requirements
- VirtualBox ([https://www.virtualbox.org](https://www.virtualbox.org))
- Vagrant ([https://www.vagrantup.com](https://www.vagrantup.com))
- PHP >= 7.2.x
- Composer installed ([https://getcomposer.org](https://getcomposer.org))

You can install all of them with homebrew ([https://brew.sh/index_de](https://brew.sh/index_de)).

    brew install virtualbox vagrant php composer
Install homestead vagrant box:
(I had some problems with the newest version, so i use the older one at version >= 9.5, < 10)

    vagrant box add --box-version '~> 9.5' laravel/homestead

## Install
Clone this repository

    git clone https://github.com/servicehome/shopw5-dev-env.git

Start the initialisation script

    initProject.sh

## Start Shopware VM
Go to the shop directory (default: shopware5) and type

     vagrant up

Then start your browser and go to the URL: **https://shopware5.test/**
