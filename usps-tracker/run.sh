#!/bin/bash

bundle exec rake db:migrate
bundle exec ruby server.rb -p 9005 -e production
