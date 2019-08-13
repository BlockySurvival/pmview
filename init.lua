local mod_storage = minetest.get_mod_storage()

local function toggle_is_enabled(player_name)
   local current = mod_storage:get_string(player_name)
   local new = (current == "disabled") and "enabled" or "disabled"
   mod_storage:set_string(player_name, new)
   return new == "enabled"
end

local function get_is_enabled(player_name)
   local v = mod_storage:get_string(player_name)
   return v == "" or v == "enabled"
end


local function get_all_connected_player_names()
   if cloaking ~= nil and cloaking.get_connected_names ~= nil then
      return cloaking.get_connected_names()
   end
   local names = {}
   for _, player in ipairs(minetest.get_connected_players()) do
      table.insert(names, player:get_player_name())
   end
   return names
end

local old_def = minetest.registered_chatcommands["msg"]
local old_func = minetest.registered_chatcommands["msg"].func

-- Soft dependency on verification so that its override will be loaded first
minetest.override_chatcommand("msg", {
   description = "Send a private message (Visible to admins and moderators)",
   params = old_def.params,
   privs = old_def.privs,
   func = function(name, param)
      res, reason = old_func(name, param)
      if res == false then
         return res, reason
      end
      local sendto, message = param:match("^(%S+)%s(.+)$") -- Guaranteed this will work by oldfunc
      local report = minetest.colorize("lime", name .. " to " .. sendto .. ": " .. message)
      for _, n in ipairs(get_all_connected_player_names()) do
         if n ~= name and n ~= sendto then
            if minetest.check_player_privs(n, {basic_privs = true}) and get_is_enabled(n) then
               minetest.chat_send_player(n, report)
            end
         end
      end
      return res, reason
   end
})

-- Break /tell (I'm tired of it)
if minetest.registered_chatcommands["tell"] then
   minetest.override_chatcommand("tell", {
      description = "Old function from the mesecons mod.  Use /msg instead",
      params = "",
      privs = {},
      func = function()
         return false, "Use /msg instead"
      end
   })
end

minetest.register_chatcommand("toggle_pmview", {
   privs = {basic_privs = true},
   description = "toggle whether you will see pmview messages",
   func = function(caller, params)
      local is_enabled = toggle_is_enabled(caller)
      if is_enabled then
         return true, "pmview enabled"
      else
         return true, "pmview disabled"
      end
   end
})
