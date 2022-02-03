local lapis = require("lapis")
local cjson = require("cjson.safe")
local Model = require("lapis.db.model").Model
local custom_error = require("./custom_error")
local us = require("underscore")

local app = lapis.Application()

rules =  {
  produkty = {
    write = true,
    read = true
  },
  kategorie = {
    write = true,
    read = true
  }
}

function authenticator(model, operation_name)
  local model_rules = rules[model]
  if not model_rules then
    return function() return false end
  else
    local rule = model_rules[operation_name]
    if not rule then
      return function() return false end
    else
      return function(record, newRecord)
        return rule == true or (type(rule) == "function" and rule(record, newRecord) == true)
      end
    end
  end
end

function getPostData()
  ngx.req.read_body()
  local validJson, data = pcall(function() return cjson.decode(ngx.req.get_body_data()) end)
  if not validJson then
    return nil
  elseif not data then
    return {}
  else
    return us.first(us.values(data))
  end
end

-- MAIN
app:get("/", function()
  
  return "Server running. Lapis " .. require("lapis.version") .. " , " .. tostring(_VERSION)
end)

-- CREATE
app:post("/:model", function(self)
  local model = Model:extend(self.params.model)
  local data = getPostData()
  if not data or data == {} then
    return custom_error.post_params_empty()
  else
    local authenticate = authenticator(self.params.model, 'write')
    if not authenticate(nil, data) then
      return custom_error.unauthorized()
    else
      local create_successful = pcall(function() model:create(data) end)
      if not create_successful then
        return custom_error.database_operation("Record could not be created.")
      else
        return { json = { [self.params.model] = { data } } }
      end
    end
  end
end)

-- Find One
app:get("/:model/:id", function(self)
  local model = Model:extend(self.params.model)
  local find_successful, find_result = pcall(function() return model:find(self.params.id) end)
  if not find_successful then
    return custom_error.unknown_model(self.params.model)
  else
    local record = find_result
    if not record then
      return custom_error.invalid_id(self.params.id)
    else
      local authenticate = authenticator(self.params.model, 'read')
      if not authenticate(record) then
        return custom_error.unauthorized()
      else
        return { json = { [self.params.model] = { record } } }
      end
    end
  end
end)

-- Find Many
app:get("/:model", function(self)
  local authenticate = authenticator(self.params.model, 'read')
  if not authenticate then
    return custom_error.unauthorized()
  else
    local model = Model:extend(self.params.model)
    local paginated = model:paginated()
    local find_successful, find_result = pcall(function() return paginated:get_all() end)
    if not find_successful then
      return custom_error.unknown_model(self.params.model)
    else
      local records = us.select(find_result, function(record)
        return authenticate(record)
      end)
      return { json = { [self.params.model] = records } }
    end
  end
end)

-- UPDATE, DELETE
app:post("/:model/:id", function(self)
  local model = Model:extend(self.params.model)
  local find_successful, find_result = pcall(function() return model:find(tostring(self.params.id)) end)
  if not find_successful then
    return custom_error.unknown_model(self.params.model)
  else
    local record = find_result
    if not record then
      return custom_error.invalid_id(self.params.id)
    else
      local data = getPostData()
      if not data then
        return custom_error.post_params_empty()
      else
        local authenticate = authenticator(self.params.model, 'write')
        if not authenticate(record, data) then
          return custom_error.unauthorized()
        else
          local database_operation_successful, info = pcall(function()
            if us.is_empty(data) then
              record:delete()
            else
              record:update(data)
            end
          end)
          if not database_operation_successful then
            return custom_error.database_operation("Unable to create or delete record")
          else
            return { json = { [self.params.model] = data } }
          end
        end
      end
    end
  end
end)

return app