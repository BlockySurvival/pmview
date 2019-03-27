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
      local sendto, message = param:match("^(%S+)%s(.+)$") -- Guranateed this will work by oldfunc
      local report = minetest.colorize("lime", name .. " to " .. sendto .. ": " .. message)
      for _, player in ipairs(minetest.get_connected_players()) do
         local n = player:get_player_name()
         if n ~= name and n ~= sendto then
            if minetest.check_player_privs(n, {basic_privs = true}) then
               minetest.chat_send_player(n, report)
            end
         end
      end
      return res, reason
   end
})

-- Break /tell (I'm tired of it)
minetest.override_chatcommand("tell", {
   description = "Old function from the mesecons mod.  Use /msg instead",
   params = "",
   privs = {},
   function = function()
      return false, "Use /msg instead"
   end
})
