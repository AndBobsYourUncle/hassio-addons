#!/bin/bash

bundle exec rake db:create db:migrate
bundle exec ruby server.rb -p 9005
