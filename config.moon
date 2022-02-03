import config from require "lapis.config"

config "development", ->
  mysql ->
      host "127.0.0.1"
      user "root"
      password "root"
      database "lapis"