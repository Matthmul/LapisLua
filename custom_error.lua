local config = require('lapis.config').get()
local cjson = require('cjson')

function custom_error(errors)
    if config.logging.requests == true then
      print('Data error: ' .. cjson.encode(errors) .. '\n')
    end
    return { json = { errors = errors }, status = 422 }
  end
  
  return {
    unauthorized = function()
      return custom_error({ unauthorized = { 'Unauthorized access' } })
    end,
  
    json_err = function(json_err)
      return custom_error({ json = { json_err } })
    end,
  
    post_params_empty = function()
      return custom_error({ post = { 'Missing parameters for POST method' } })
    end,
  
    unknown_model = function(model)
      return custom_error({ database = { 'Unknow database model: ' .. model } })
    end,
  
    invalid_id = function(id)
      return custom_error({ database = { 'Invalid ID: ' .. id } })
    end,
  
    database_operation = function(operation)
      return custom_error({ database = { operation } })
    end
  }