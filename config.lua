local config = require("lapis.config")

config("development", {
mysql  = {
    -- backend = "lue-resty-mysql",
    host = "127.0.0.1",
    user = "root",
    password = "root",
    database = "lapis"
  },
  port = 8080
})

config("production", {
mysql  = {
    -- backend = "lue-resty-mysql",
    host = "127.0.0.1",
    user = "root",
    password = "root",
    database = "lapis"
  },
  port = 80,
  logging = {
    queries = true,
    request = true
  }
})