import config from require "lapis.config"
import cjson from require "cjson"


class custom_error = (errors) ->
    if config.logging.requests == true 
      print 'Data error: ', cjson.encode(errors), '\n'
    return { json = { errors = errors }, status = 422 }
  

unauthorized = ->
    return custom_error({ unauthorized = { 'Unauthorized access' } })

json_err = (json_err) ->
    return custom_error({ json = { json_err } })

post_params_empty = ->
    return custom_error({ post = { 'Missing parameters for POST method' } })

unknown_model = (model) ->
    return custom_error({ database = { 'Unknow database model: ' .. model } })

invalid_id = (id) ->
    return custom_error({ database = { 'Invalid ID: ' .. id } })

database_operation = (operation) ->
    return custom_error({ database = { operation } })