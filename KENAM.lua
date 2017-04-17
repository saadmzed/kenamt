--[[ 
   _____    _        _    _    _____    Dev @EMADOFFICAL
  |_   _|__| |__    / \  | | _| ____|   Dev @lIMyIl 
    | |/ __| '_ \  / _ \ | |/ /  _|     Dev @IX00XI
    | |\__ \ | | |/ ___ \|   <| |___    Dev @H_173
    |_||___/_| |_/_/   \_\_|\_\_____|   Dev @lIESIl
              CH > @lTSHAKEl_CH
--]]
serpent = require('serpent')
serp = require 'serpent'.block
http = require("socket.http")
https = require("ssl.https")
http.TIMEOUT = 10
lgi = require ('lgi')
JSON = require('dkjson')
redis = (loadfile "./libs/JSON.lua")()
redis = (loadfile "./libs/redis.lua")()
database = Redis.connect('127.0.0.1', 6379)
notify = lgi.require('Notify')
tdcli = dofile('tdcli.lua')
notify.init ("Telegram updates")
sudos = dofile('sudo.lua')
chats = {}
day = 86400
  -----------------------------------------------------------------------------------------------
                                     -- start functions --
  -----------------------------------------------------------------------------------------------
function is_sudo(msg)
  local var = false
  for k,v in pairs(sudo_users) do
    if msg.sender_user_id_ == v then
      var = true
    end
  end
  return var
end
-----------------------------------------------------------------------------------------------
function is_admin(user_id)
    local var = false
	local hashs =  'bot:admins:'
    local admin = database:sismember(hashs, user_id)
	 if admin then
	    var = true
	 end
  for k,v in pairs(sudo_users) do
    if user_id == v then
      var = true
    end
  end
    return var
end
-----------------------------------------------------------------------------------------------
function is_vip_group(gp_id)
    local var = false
	local hashs =  'bot:vipgp:'
    local vip = database:sismember(hashs, gp_id)
	 if vip then
	    var = true
	 end
    return var
end
-----------------------------------------------------------------------------------------------
function is_owner(user_id, chat_id)
    local var = false
    local hash =  'bot:owners:'..chat_id
    local owner = database:sismember(hash, user_id)
	local hashs =  'bot:admins:'
    local admin = database:sismember(hashs, user_id)
	 if owner then
	    var = true
	 end
	 if admin then
	    var = true
	 end
    for k,v in pairs(sudo_users) do
    if user_id == v then
      var = true
    end
	end
    return var
end

-----------------------------------------------------------------------------------------------
function is_mod(user_id, chat_id)
    local var = false
    local hash =  'bot:mods:'..chat_id
    local mod = database:sismember(hash, user_id)
	local hashs =  'bot:admins:'
    local admin = database:sismember(hashs, user_id)
	local hashss =  'bot:owners:'..chat_id
    local owner = database:sismember(hashss, user_id)
	 if mod then
	    var = true
	 end
	 if owner then
	    var = true
	 end
	 if admin then
	    var = true
	 end
    for k,v in pairs(sudo_users) do
    if user_id == v then
      var = true
    end
	end
    return var
end
-----------------------------------------------------------------------------------------------
function is_banned(user_id, chat_id)
    local var = false
	local hash = 'bot:banned:'..chat_id
    local banned = database:sismember(hash, user_id)
	 if banned then
	    var = true
	 end
    return var
end

function is_gbanned(user_id)
  local var = false
  local hash = 'bot:gbanned:'
  local banned = database:sismember(hash, user_id)
  if banned then
    var = true
  end
  return var
end
-----------------------------------------------------------------------------------------------
function is_muted(user_id, chat_id)
    local var = false
	local hash = 'bot:muted:'..chat_id
    local banned = database:sismember(hash, user_id)
	 if banned then
	    var = true
	 end
    return var
end

function is_gmuted(user_id, chat_id)
    local var = false
	local hash = 'bot:gmuted:'..chat_id
    local banned = database:sismember(hash, user_id)
	 if banned then
	    var = true
	 end
    return var
end
-----------------------------------------------------------------------------------------------
function get_info(user_id)
  if database:hget('bot:username',user_id) then
    text = '@'..(string.gsub(database:hget('bot:username',user_id), 'false', '') or '')..''
  end
  get_user(user_id)
  return text
  --db:hrem('bot:username',user_id)
end
function get_user(user_id)
  function dl_username(arg, data)
    username = data.username or ''

    --vardump(data)
    database:hset('bot:username',data.id_,data.username_)
  end
  tdcli_function ({
    ID = "GetUser",
    user_id_ = user_id
  }, dl_username, nil)
end
local function getMessage(chat_id, message_id,cb)
  tdcli_function ({
    ID = "GetMessage",
    chat_id_ = chat_id,
    message_id_ = message_id
  }, cb, nil)
end
-----------------------------------------------------------------------------------------------
local function check_filter_words(msg, value)
  local hash = 'bot:filters:'..msg.chat_id_
  if hash then
    local names = database:hkeys(hash)
    local text = ''
    for i=1, #names do
	   if string.match(value:lower(), names[i]:lower()) and not is_mod(msg.sender_user_id_, msg.chat_id_)then
	     local id = msg.id_
         local msgs = {[0] = id}
         local chat = msg.chat_id_
        delete_msg(chat,msgs)
       end
    end
  end
end
-----------------------------------------------------------------------------------------------
function resolve_username(username,cb)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, cb, nil)
end
  -----------------------------------------------------------------------------------------------
function changeChatMemberStatus(chat_id, user_id, status)
  tdcli_function ({
    ID = "ChangeChatMemberStatus",
    chat_id_ = chat_id,
    user_id_ = user_id,
    status_ = {
      ID = "ChatMemberStatus" .. status
    },
  }, dl_cb, nil)
end
  -----------------------------------------------------------------------------------------------
function getInputFile(file)
  if file:match('/') then
    infile = {ID = "InputFileLocal", path_ = file}
  elseif file:match('^%d+$') then
    infile = {ID = "InputFileId", id_ = file}
  else
    infile = {ID = "InputFilePersistentId", persistent_id_ = file}
  end

  return infile
end
  -----------------------------------------------------------------------------------------------
function del_all_msgs(chat_id, user_id)
  tdcli_function ({
    ID = "DeleteMessagesFromUser",
    chat_id_ = chat_id,
    user_id_ = user_id
  }, dl_cb, nil)
end

  local function deleteMessagesFromUser(chat_id, user_id, cb, cmd)
    tdcli_function ({
      ID = "DeleteMessagesFromUser",
      chat_id_ = chat_id,
      user_id_ = user_id
    },cb or dl_cb, cmd)
  end
  -----------------------------------------------------------------------------------------------
function getChatId(id)
  local chat = {}
  local id = tostring(id)
  
  if id:match('^-100') then
    local channel_id = id:gsub('-100', '')
    chat = {ID = channel_id, type = 'channel'}
  else
    local group_id = id:gsub('-', '')
    chat = {ID = group_id, type = 'group'}
  end
  
  return chat
end
  -----------------------------------------------------------------------------------------------
function chat_leave(chat_id, user_id)
  changeChatMemberStatus(chat_id, user_id, "Left")
end
  -----------------------------------------------------------------------------------------------
function from_username(msg)
   function gfrom_user(extra,result,success)
   if result.username_ then
   F = result.username_
   else
   F = 'nil'
   end
    return F
   end
  local username = getUser(msg.sender_user_id_,gfrom_user)
  return username
end
  -----------------------------------------------------------------------------------------------
function chat_kick(chat_id, user_id)
  changeChatMemberStatus(chat_id, user_id, "Kicked")
end
  -----------------------------------------------------------------------------------------------
function do_notify (user, msg)
  local n = notify.Notification.new(user, msg)
  n:show ()
end
  -----------------------------------------------------------------------------------------------
local function getParseMode(parse_mode)  
  if parse_mode then
    local mode = parse_mode:lower()
  
    if mode == 'markdown' or mode == 'md' then
      P = {ID = "TextParseModeMarkdown"}
    elseif mode == 'html' then
      P = {ID = "TextParseModeHTML"}
    end
  end
  return P
end
  -----------------------------------------------------------------------------------------------
local function getMessage(chat_id, message_id,cb)
  tdcli_function ({
    ID = "GetMessage",
    chat_id_ = chat_id,
    message_id_ = message_id
  }, cb, nil)
end
-----------------------------------------------------------------------------------------------
function sendContact(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, phone_number, first_name, last_name, user_id)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = from_background,
    reply_markup_ = reply_markup,
    input_message_content_ = {
      ID = "InputMessageContact",
      contact_ = {
        ID = "Contact",
        phone_number_ = phone_number,
        first_name_ = first_name,
        last_name_ = last_name,
        user_id_ = user_id
      },
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function sendPhoto(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, photo, caption)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = from_background,
    reply_markup_ = reply_markup,
    input_message_content_ = {
      ID = "InputMessagePhoto",
      photo_ = getInputFile(photo),
      added_sticker_file_ids_ = {},
      width_ = 0,
      height_ = 0,
      caption_ = caption
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function getUserFull(user_id,cb)
  tdcli_function ({
    ID = "GetUserFull",
    user_id_ = user_id
  }, cb, nil)
end
-----------------------------------------------------------------------------------------------
function vardump(value)
  print(serpent.block(value, {comment=false}))
end
-----------------------------------------------------------------------------------------------
function dl_cb(arg, data)
end
-----------------------------------------------------------------------------------------------
local function send(chat_id, reply_to_message_id, disable_notification, text, disable_web_page_preview, parse_mode)
  local TextParseMode = getParseMode(parse_mode)
  
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = 1,
    reply_markup_ = nil,
    input_message_content_ = {
      ID = "InputMessageText",
      text_ = text,
      disable_web_page_preview_ = disable_web_page_preview,
      clear_draft_ = 0,
      entities_ = {},
      parse_mode_ = TextParseMode,
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function sendaction(chat_id, action, progress)
  tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessage" .. action .. "Action",
      progress_ = progress or 100
    }
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function changetitle(chat_id, title)
  tdcli_function ({
    ID = "ChangeChatTitle",
    chat_id_ = chat_id,
    title_ = title
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function edit(chat_id, message_id, reply_markup, text, disable_web_page_preview, parse_mode)
  local TextParseMode = getParseMode(parse_mode)
  tdcli_function ({
    ID = "EditMessageText",
    chat_id_ = chat_id,
    message_id_ = message_id,
    reply_markup_ = reply_markup,
    input_message_content_ = {
      ID = "InputMessageText",
      text_ = text,
      disable_web_page_preview_ = disable_web_page_preview,
      clear_draft_ = 0,
      entities_ = {},
      parse_mode_ = TextParseMode,
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function setphoto(chat_id, photo)
  tdcli_function ({
    ID = "ChangeChatPhoto",
    chat_id_ = chat_id,
    photo_ = getInputFile(photo)
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function add_user(chat_id, user_id, forward_limit)
  tdcli_function ({
    ID = "AddChatMember",
    chat_id_ = chat_id,
    user_id_ = user_id,
    forward_limit_ = forward_limit or 50
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function delmsg(arg,data)
  for k,v in pairs(data.messages_) do
    delete_msg(v.chat_id_,{[0] = v.id_})
  end
end
-----------------------------------------------------------------------------------------------
function unpinmsg(channel_id)
  tdcli_function ({
    ID = "UnpinChannelMessage",
    channel_id_ = getChatId(channel_id).ID
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
local function blockUser(user_id)
  tdcli_function ({
    ID = "BlockUser",
    user_id_ = user_id
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
local function unblockUser(user_id)
  tdcli_function ({
    ID = "UnblockUser",
    user_id_ = user_id
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
local function getBlockedUsers(offset, limit)
  tdcli_function ({
    ID = "GetBlockedUsers",
    offset_ = offset,
    limit_ = limit
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function delete_msg(chatid,mid)
  tdcli_function ({
  ID="DeleteMessages", 
  chat_id_=chatid, 
  message_ids_=mid
  },
  dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function chat_del_user(chat_id, user_id)
  changeChatMemberStatus(chat_id, user_id, 'Editor')
end
-----------------------------------------------------------------------------------------------
function getChannelMembers(channel_id, offset, filter, limit)
  if not limit or limit > 200 then
    limit = 200
  end
  tdcli_function ({
    ID = "GetChannelMembers",
    channel_id_ = getChatId(channel_id).ID,
    filter_ = {
      ID = "ChannelMembers" .. filter
    },
    offset_ = offset,
    limit_ = limit
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function getChannelFull(channel_id)
  tdcli_function ({
    ID = "GetChannelFull",
    channel_id_ = getChatId(channel_id).ID
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
local function channel_get_bots(channel,cb)
local function callback_admins(extra,result,success)
    limit = result.member_count_
    getChannelMembers(channel, 0, 'Bots', limit,cb)
    channel_get_bots(channel,get_bots)
end

  getChannelFull(channel,callback_admins)
end
-----------------------------------------------------------------------------------------------
local function getInputMessageContent(file, filetype, caption)
  if file:match('/') then
    infile = {ID = "InputFileLocal", path_ = file}
  elseif file:match('^%d+$') then
    infile = {ID = "InputFileId", id_ = file}
  else
    infile = {ID = "InputFilePersistentId", persistent_id_ = file}
  end

  local inmsg = {}
  local filetype = filetype:lower()

  if filetype == 'animation' then
    inmsg = {ID = "InputMessageAnimation", animation_ = infile, caption_ = caption}
  elseif filetype == 'audio' then
    inmsg = {ID = "InputMessageAudio", audio_ = infile, caption_ = caption}
  elseif filetype == 'document' then
    inmsg = {ID = "InputMessageDocument", document_ = infile, caption_ = caption}
  elseif filetype == 'photo' then
    inmsg = {ID = "InputMessagePhoto", photo_ = infile, caption_ = caption}
  elseif filetype == 'sticker' then
    inmsg = {ID = "InputMessageSticker", sticker_ = infile, caption_ = caption}
  elseif filetype == 'video' then
    inmsg = {ID = "InputMessageVideo", video_ = infile, caption_ = caption}
  elseif filetype == 'voice' then
    inmsg = {ID = "InputMessageVoice", voice_ = infile, caption_ = caption}
  end

  return inmsg
end

-----------------------------------------------------------------------------------------------
function send_file(chat_id, type, file, caption,wtf)
local mame = (wtf or 0)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = mame,
    disable_notification_ = 0,
    from_background_ = 1,
    reply_markup_ = nil,
    input_message_content_ = getInputMessageContent(file, type, caption),
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function getUser(user_id, cb)
  tdcli_function ({
    ID = "GetUser",
    user_id_ = user_id
  }, cb, nil)
end
-----------------------------------------------------------------------------------------------
function pin(channel_id, message_id, disable_notification) 
   tdcli_function ({ 
     ID = "PinChannelMessage", 
     channel_id_ = getChatId(channel_id).ID, 
     message_id_ = message_id, 
     disable_notification_ = disable_notification 
   }, dl_cb, nil) 
end 
-----------------------------------------------------------------------------------------------
function tdcli_update_callback(data)
	-------------------------------------------
  if (data.ID == "UpdateNewMessage") then
    local msg = data.message_
    --vardump(data)
    local d = data.disable_notification_
    local chat = chats[msg.chat_id_]
	-------------------------------------------
	if msg.date_ < (os.time() - 30) then
       return false
    end
	-------------------------------------------
	if not database:get("bot:enable:"..msg.chat_id_) and not is_admin(msg.sender_user_id_, msg.chat_id_) then
      return false
    end
    -------------------------------------------
      if msg and msg.send_state_.ID == "MessageIsSuccessfullySent" then
	  --vardump(msg)
	   function get_mymsg_contact(extra, result, success)
             --vardump(result)
       end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,get_mymsg_contact)
         return false 
      end
    -------------* EXPIRE *-----------------
    if not database:get("bot:charge:"..msg.chat_id_) then
     if database:get("bot:enable:"..msg.chat_id_) then
      database:del("bot:enable:"..msg.chat_id_)
      for k,v in pairs(sudo_users) do
        send(v, 0, 1, "link \nLink : "..(database:get("bot:group:link"..msg.chat_id_) or "settings").."\nID : "..msg.chat_id_..'\n\nuse  #leave\n\n/leave'..msg.chat_id_..'\nuse #join:\n/join'..msg.chat_id_..'\n_________________\nuse plan...\n\n<code>30 days:</code>\n/plan1'..msg.chat_id_..'\n\n<code>90 days:</code>\n/plan2'..msg.chat_id_..'\n\n<code>No fanil:</code>\n/plan3'..msg.chat_id_, 1, 'html')
      end
      end
    end
    --------- ANTI FLOOD -------------------
	local hash = 'flood:max:'..msg.chat_id_
    if not database:get(hash) then
        floodMax = 5
    else
        floodMax = tonumber(database:get(hash))
    end

    local hash = 'flood:time:'..msg.chat_id_
    if not database:get(hash) then
        floodTime = 3
    else
        floodTime = tonumber(database:get(hash))
    end
    if not is_mod(msg.sender_user_id_, msg.chat_id_) then
        local hashse = 'anti-flood:'..msg.chat_id_
        if not database:get(hashse) then
                if not is_mod(msg.sender_user_id_, msg.chat_id_) then
                    local hash = 'flood:'..msg.sender_user_id_..':'..msg.chat_id_..':msg-num'
                    local msgs = tonumber(database:get(hash) or 0)
                    if msgs > (floodMax - 1) then
                        local user = msg.sender_user_id_
                        local chat = msg.chat_id_
                        local channel = msg.chat_id_
						 local user_id = msg.sender_user_id_
						 local banned = is_banned(user_id, msg.chat_id_)
                         if banned then
						local id = msg.id_
        				local msgs = {[0] = id}
       					local chat = msg.chat_id_
       						       del_all_msgs(msg.chat_id_, msg.sender_user_id_)
						    else
						 local id = msg.id_
                         local msgs = {[0] = id}
                         local chat = msg.chat_id_
		                chat_kick(msg.chat_id_, msg.sender_user_id_)
						 del_all_msgs(msg.chat_id_, msg.sender_user_id_)
						user_id = msg.sender_user_id_
						local bhash =  'bot:banned:'..msg.chat_id_
                        database:sadd(bhash, user_id)
                           send(msg.chat_id_, msg.id_, 1, '> _ID_  *('..msg.sender_user_id_..')* \n_Spamming Not Allowed Here._\n`Spammer Banned!!`', 1, 'md')
					  end
                    end
                    database:setex(hash, floodTime, msgs+1)
                end
        end
	end
	
	local hash = 'flood:max:warn'..msg.chat_id_
    if not database:get(hash) then
        floodMax = 5
    else
        floodMax = tonumber(database:get(hash))
    end

    local hash = 'flood:time:'..msg.chat_id_
    if not database:get(hash) then
        floodTime = 3
    else
        floodTime = tonumber(database:get(hash))
    end
    if not is_mod(msg.sender_user_id_, msg.chat_id_) then
        local hashse = 'anti-flood:warn'..msg.chat_id_
        if not database:get(hashse) then
                if not is_mod(msg.sender_user_id_, msg.chat_id_) then
                    local hash = 'flood:'..msg.sender_user_id_..':'..msg.chat_id_..':msg-num'
                    local msgs = tonumber(database:get(hash) or 0)
                    if msgs > (floodMax - 1) then
                        local user = msg.sender_user_id_
                        local chat = msg.chat_id_
                        local channel = msg.chat_id_
						 local user_id = msg.sender_user_id_
						 local banned = is_banned(user_id, msg.chat_id_)
                         if banned then
						local id = msg.id_
        				local msgs = {[0] = id}
       					local chat = msg.chat_id_
       						       del_all_msgs(msg.chat_id_, msg.sender_user_id_)
						    else
						 local id = msg.id_
                         local msgs = {[0] = id}
                         local chat = msg.chat_id_
						 del_all_msgs(msg.chat_id_, msg.sender_user_id_)
						user_id = msg.sender_user_id_
						local bhash =  'bot:muted:'..msg.chat_id_
                        database:sadd(bhash, user_id)
                           send(msg.chat_id_, msg.id_, 1, '> _ID_  *('..msg.sender_user_id_..')* \n_Spamming Not Allowed Here._\n`Spammer Muted!!`', 1, 'md')

					  end
                    end
                    database:setex(hash, floodTime, msgs+1)
                end
        end
	end
	-------------------------------------------
	database:incr("bot:allmsgs")
	if msg.chat_id_ then
      local id = tostring(msg.chat_id_)
      if id:match('-100(%d+)') then
        if not database:sismember("bot:groups",msg.chat_id_) then
            database:sadd("bot:groups",msg.chat_id_)
        end
        elseif id:match('^(%d+)') then
        if not database:sismember("bot:userss",msg.chat_id_) then
            database:sadd("bot:userss",msg.chat_id_)
        end
        else
        if not database:sismember("bot:groups",msg.chat_id_) then
            database:sadd("bot:groups",msg.chat_id_)
        end
     end
    end
	-------------------------------------------
    -------------* MSG TYPES *-----------------
   if msg.content_ then
   	if msg.reply_markup_ and  msg.reply_markup_.ID == "ReplyMarkupInlineKeyboard" then
		print("Send INLINE KEYBOARD")
	msg_type = 'MSG:Inline'
	-------------------------
    elseif msg.content_.ID == "MessageText" then
	text = msg.content_.text_
		print("SEND TEXT")
	msg_type = 'MSG:Text'
	-------------------------
	elseif msg.content_.ID == "MessagePhoto" then
	print("SEND PHOTO")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Photo'
	-------------------------
	elseif msg.content_.ID == "MessageChatAddMembers" then
	print("NEW ADD TO GROUP")
	msg_type = 'MSG:NewUserAdd'
	-------------------------
	elseif msg.content_.ID == "MessageChatJoinByLink" then
		print("JOIN TO GROUP")
	msg_type = 'MSG:NewUserLink'
	-------------------------
	elseif msg.content_.ID == "MessageSticker" then
		print("SEND STICKER")
	msg_type = 'MSG:Sticker'
	-------------------------
	elseif msg.content_.ID == "MessageAudio" then
		print("SEND MUSIC")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Audio'
	-------------------------
	elseif msg.content_.ID == "MessageVoice" then
		print("SEND VOICE")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Voice'
	-------------------------
	elseif msg.content_.ID == "MessageVideo" then
		print("SEND VIDEO")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Video'
	-------------------------
	elseif msg.content_.ID == "MessageAnimation" then
		print("SEND GIF")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Gif'
	-------------------------
	elseif msg.content_.ID == "MessageLocation" then
		print("SEND LOCATION")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Location'
	-------------------------
	elseif msg.content_.ID == "MessageChatJoinByLink" or msg.content_.ID == "MessageChatAddMembers" then
	msg_type = 'MSG:NewUser'
	-------------------------
	elseif msg.content_.ID == "MessageContact" then
		print("SEND CONTACT")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Contact'
	-------------------------
	end
   end
    -------------------------------------------
    -------------------------------------------
    if ((not d) and chat) then
      if msg.content_.ID == "MessageText" then
        do_notify (chat.title_, msg.content_.text_)
      else
        do_notify (chat.title_, msg.content_.ID)
      end
    end
  -----------------------------------------------------------------------------------------------
                                     -- end functions --
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
                                     -- start code --
  -----------------------------------------------------------------------------------------------
  -------------------------------------- Process mod --------------------------------------------
  -----------------------------------------------------------------------------------------------
  
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  --------------------------******** START MSG CHECKS ********-------------------------------------------
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
if is_banned(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
		  chat_kick(msg.chat_id_, msg.sender_user_id_)
		  return 
end

if is_gbanned(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
		  chat_kick(msg.chat_id_, msg.sender_user_id_)
		  return 
end

if is_muted(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        local user_id = msg.sender_user_id_
          delete_msg(chat,msgs)
		  return 
end
if database:get('bot:muteall'..msg.chat_id_) and not is_mod(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
        return 
end

if database:get('bot:muteallwarn'..msg.chat_id_) and not is_mod(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Mute all in Group</code>", 1, 'html')
        return 
end

if database:get('bot:muteallban'..msg.chat_id_) and not is_mod(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Mute all in Group</code>\n<b>The Block</b>", 1, 'html')
        return 
end
    database:incr('user:msgs'..msg.chat_id_..':'..msg.sender_user_id_)
	database:incr('group:msgs'..msg.chat_id_)
if msg.content_.ID == "MessagePinMessage" then
  if database:get('pinnedmsg'..msg.chat_id_) and database:get('bot:pin:mute'..msg.chat_id_) then
   unpinmsg(msg.chat_id_)
   local pin_id = database:get('pinnedmsg'..msg.chat_id_)
         pin(msg.chat_id_,pin_id,0)
   end
end
    database:incr('user:msgs'..msg.chat_id_..':'..msg.sender_user_id_)
	database:incr('group:msgs'..msg.chat_id_)
if msg.content_.ID == "MessagePinMessage" then
  if database:get('pinnedmsg'..msg.chat_id_) and database:get('bot:pin:warn'..msg.chat_id_) then
   send(msg.chat_id_, msg.id_, 1, "*> Your ID :* _"..msg.sender_user_id_.."_\n*> UserName :* "..get_info(msg.sender_user_id_).."\n*> Pin is Locked Group*", 1, 'md')
   unpinmsg(msg.chat_id_)
   local pin_id = database:get('pinnedmsg'..msg.chat_id_)
         pin(msg.chat_id_,pin_id,0)
   end
end
if database:get('bot:viewget'..msg.sender_user_id_) then 
    if not msg.forward_info_ then
		send(msg.chat_id_, msg.id_, 1, '*Error*\n`Please send this command again and forward your post(from channel)`', 1, 'md')
		database:del('bot:viewget'..msg.sender_user_id_)
	else
		send(msg.chat_id_, msg.id_, 1, 'Your Post Views:\n> '..msg.views_..' View!', 1, 'md')
        database:del('bot:viewget'..msg.sender_user_id_)
	end
end
if msg_type == 'MSG:Photo' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
     if database:get('bot:photo:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
        if database:get('bot:photo:ban'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
		   chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Photo in Group</code>\n<b>The Block</b>", 1, 'html')

          return 
   end
        if database:get('bot:photo:warn'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Photo in Group</code>", 1, 'html')
 
          return 
   end
   end
  elseif msg_type == 'MSG:Inline' then
   if not is_mod(msg.sender_user_id_, msg.chat_id_) then
    if database:get('bot:inline:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
        if database:get('bot:inline:ban'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Inline in Group</code>\n<b>The Block</b>", 1, 'html')
          return 
   end
   
        if database:get('bot:inline:warn'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Photo in Group</code>", 1, 'html')
          return 
   end
   end
  elseif msg_type == 'MSG:Sticker' then
   if not is_mod(msg.sender_user_id_, msg.chat_id_) then
  if database:get('bot:sticker:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
        if database:get('bot:sticker:ban'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Sticker in Group</code>\n<b>The Block</b>", 1, 'html')
          return 
   end
   
        if database:get('bot:sticker:warn'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send sticker in Group</code>", 1, 'html')
          return 
   end
   end
elseif msg_type == 'MSG:NewUserLink' then
  if database:get('bot:tgservice:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   function get_welcome(extra,result,success)
    if database:get('welcome:'..msg.chat_id_) then
        text = database:get('welcome:'..msg.chat_id_)
    else
        text = 'Hi {firstname} 😃'
    end
    local text = text:gsub('{firstname}',(result.first_name_ or ''))
    local text = text:gsub('{lastname}',(result.last_name_ or ''))
    local text = text:gsub('{username}',(result.username_ or ''))
         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
   end
	  if database:get("bot:welcome"..msg.chat_id_) then
        getUser(msg.sender_user_id_,get_welcome)
      end
elseif msg_type == 'MSG:NewUserAdd' then
  if database:get('bot:tgservice:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
      --vardump(msg)
   if msg.content_.members_[0].username_ and msg.content_.members_[0].username_:match("[Bb][Oo][Tt]$") then
      if database:get('bot:bots:mute'..msg.chat_id_) and not is_mod(msg.content_.members_[0].id_, msg.chat_id_) then
		 chat_kick(msg.chat_id_, msg.content_.members_[0].id_)
		 return false
	  end
   end
   if is_banned(msg.content_.members_[0].id_, msg.chat_id_) then
		 chat_kick(msg.chat_id_, msg.content_.members_[0].id_)
		 return false
   end
   if database:get("bot:welcome"..msg.chat_id_) then
    if database:get('welcome:'..msg.chat_id_) then
        text = database:get('welcome:'..msg.chat_id_)
    else
        text = '*Hi {firstname} 😃*'
    end
    local text = text:gsub('{firstname}',(msg.content_.members_[0].first_name_ or ''))
    local text = text:gsub('{lastname}',(msg.content_.members_[0].last_name_ or ''))
    local text = text:gsub('{username}',('@'..msg.content_.members_[0].username_ or ''))
         send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
   end
elseif msg_type == 'MSG:Contact' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
  if database:get('bot:contact:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
        if database:get('bot:contact:ban'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Contact in Group</code>", 1, 'html')
          return 
   end
   
        if database:get('bot:contact:warn'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Contact in Group</code>", 1, 'html')
          return 
   end
   end
elseif msg_type == 'MSG:Audio' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
  if database:get('bot:music:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   
        if database:get('bot:music:ban'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Music in Group</code>", 1, 'html')
          return 
   end
   
        if database:get('bot:music:warn'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Music in Group</code>", 1, 'html')
          return 
   end
   end
elseif msg_type == 'MSG:Voice' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
  if database:get('bot:voice:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
        if database:get('bot:voice:ban'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Voice in Group</code>\n<b>The Block</b>", 1, 'html')
          return 
   end
   
        if database:get('bot:voice:warn'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Voice in Group</code>", 1, 'html')
          return 
   end
   end
elseif msg_type == 'MSG:Location' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
  if database:get('bot:location:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
        if database:get('bot:location:ban'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Location in Group</code>", 1, 'html')
          return 
   end
   
        if database:get('bot:location:warn'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Location in Group</code>", 1, 'html')
          return 
   end
   end
elseif msg_type == 'MSG:Video' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
  if database:get('bot:video:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
        if database:get('bot:video:ban'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Video in Group</code>\n<b>The Block</b>", 1, 'html')
          return 
   end
   
        if database:get('bot:video:warn'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Video in Group</code>", 1, 'html')
          return 
   end
   end
elseif msg_type == 'MSG:Gif' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
  if database:get('bot:gifs:mute'..msg.chat_id_) and not is_mod(msg.sender_user_id_, msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
        if database:get('bot:gifs:ban'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Gifs in Group</code>", 1, 'html')
          return 
   end
   
        if database:get('bot:gifs:warn'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Gifs in Group</code>", 1, 'html')
          return 
   end
   end
elseif msg_type == 'MSG:Text' then
 --vardump(msg)
    if database:get("bot:group:link"..msg.chat_id_) == 'Waiting For Link!\nPls Send Group Link' and is_mod(msg.sender_user_id_, msg.chat_id_) then if text:match("(https://telegram.me/joinchat/%S+)") or text:match("(https://t.me/joinchat/%S+)") then 	 local glink = text:match("(https://telegram.me/joinchat/%S+)") or text:match("(https://t.me/joinchat/%S+)") local hash = "bot:group:link"..msg.chat_id_ database:set(hash,glink) 			 send(msg.chat_id_, msg.id_, 1, '*New link Set!*', 1, 'md') send(msg.chat_id_, 0, 1, '<b>New Group link:</b>\n'..glink, 1, 'html')
      end
   end
    function check_username(extra,result,success)
	 --vardump(result)
	local username = (result.username_ or '')
	local svuser = 'user:'..result.id_
	if username then
      database:hset(svuser, 'username', username)
    end
	if username and username:match("[Bb][Oo][Tt]$") then
      if database:get('bot:bots:mute'..msg.chat_id_) and not is_mod(result.id_, msg.chat_id_) then
		 chat_kick(msg.chat_id_, result.id_)
		 return false
		 end
	  end
   end
    getUser(msg.sender_user_id_,check_username)
   database:set('bot:editid'.. msg.id_,msg.content_.text_)
   if not is_mod(msg.sender_user_id_, msg.chat_id_) then
    check_filter_words(msg, text)
	if text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or 
text:match("[Tt].[Mm][Ee]") or
text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
     if database:get('bot:links:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
       if database:get('bot:links:ban'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        local user_id = msg.sender_user_id_
        delete_msg(chat,msgs)
chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Links in Group</code>\n<b>The Block</b>", 1, 'html')
  end
       if database:get('bot:links:warn'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        local user_id = msg.sender_user_id_
        delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Links in Group</code>", 1, 'html')
	end
 end

            if text then
              local _nl, ctrl_chars = string.gsub(text, '%c', '')
              local _nl, real_digits = string.gsub(text, '%d', '')
              local id = msg.id_
              local msgs = {[0] = id}
              local chat = msg.chat_id_
              local hash = 'bot:sens:spam'..msg.chat_id_
              if not database:get(hash) then
                sens = 100
              else
                sens = tonumber(database:get(hash))
              end
              if database:get('bot:spam:mute'..msg.chat_id_) and string.len(text) > (sens) or ctrl_chars > (sens) or real_digits > (sens) then
                delete_msg(chat,msgs)
                print("Deleted [Lock] [Spam] [NS70]")
              end
          end 
          
            if text then
              local _nl, ctrl_chars = string.gsub(text, '%c', '')
              local _nl, real_digits = string.gsub(text, '%d', '')
              local id = msg.id_
              local msgs = {[0] = id}
              local chat = msg.chat_id_
              local hash = 'bot:sens:spam:warn'..msg.chat_id_
              if not database:get(hash) then
                sens = 100
              else
                sens = tonumber(database:get(hash))
              end
              if database:get('bot:spam:warn'..msg.chat_id_) and string.len(text) > (sens) or ctrl_chars > (sens) or real_digits > (sens) then
                delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Spam in Group</code>", 1, 'html')
                print("Deleted [Lock] [Spam] [NS70]")
              end
          end 
          
            if text then
              local _nl, ctrl_chars = string.gsub(text, '%c', '')
              local _nl, real_digits = string.gsub(text, '%d', '')
              local id = msg.id_
              local msgs = {[0] = id}
              local chat = msg.chat_id_
              local hash = 'bot:sens:spam:ban'..msg.chat_id_
              if not database:get(hash) then
                sens = 100
              else
                sens = tonumber(database:get(hash))
              end
              if database:get('bot:spam:ban'..msg.chat_id_) and string.len(text) > (sens) or ctrl_chars > (sens) or real_digits > (sens) then
                delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Spam in Group</code>\n<b>The Block</b>", 1, 'html')
          print("Deleted [Lock] [Spam] [NS70]")
              end
          end  

	if text then
     if database:get('bot:text:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
        if database:get('bot:text:ban'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Text in Group</code>\n<b>The Block</b>", 1, 'html')
          return 
   end
   
        if database:get('bot:text:warn'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Text in Group</code>", 1, 'html')
          return 
   end
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
end
end
if msg.forward_info_ then
if database:get('bot:forward:ban'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        local user_id = msg.sender_user_id_
        delete_msg(chat,msgs)
		                chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Forward in Group</code>\n<b>The Block</b>", 1, 'html')
	end
   end

if msg.forward_info_ then
if database:get('bot:forward:warn'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        local user_id = msg.sender_user_id_
        delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Forward in Group</code>", 1, 'html')
	end
   end
end
elseif msg_type == 'MSG:Text' then
   if text:match("@") or msg.content_.entities_[0] and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
        if database:get('bot:tag:ban'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Tag{@} in Group</code>\n<b>The Block</b>", 1, 'html')
          return 
   end
   
        if database:get('bot:tag:warn'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Tag{@} in Group</code>", 1, 'html')
          return 
   end
 end
   	if text:match("#") then
      if database:get('bot:hashtag:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
        if database:get('bot:hashtag:ban'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Hashtag{#} in Group</code>\n<b>The Block</b>", 1, 'html')
          return 
   end
   
        if database:get('bot:hashtag:warn'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Hashtag{#} in Group</code>", 1, 'html')
          return 
   end
end

   	if text:match("/") then
      if database:get('bot:cmd:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end 
	
      if database:get('bot:cmd:ban'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        local user_id = msg.sender_user_id_
        delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send CMD{/} in Group</code>\n<b>The Block</b>", 1, 'html')
	end 
	      if database:get('bot:cmd:warn'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        local user_id = msg.sender_user_id_
        delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send CMD{/} in Group</code>", 1, 'html')
	end 
	end
   	if text:match("[Hh][Tt][Tt][Pp][Ss]://") or text:match("[Hh][Tt][Tt][Pp]://") or text:match(".[Ii][Rr]") or text:match(".[Cc][Oo][Mm]") or text:match(".[Oo][Rr][Gg]") or text:match(".[Ii][Nn][Ff][Oo]") or text:match("[Ww][Ww][Ww].") or text:match(".[Tt][Kk]") then
      if database:get('bot:webpage:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
        if database:get('bot:webpage:ban'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Webpage in Group</code>\n<b>The Block</b>", 1, 'html')
          return 
   end
   
        if database:get('bot:webpage:warn'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Webpage in Group</code>", 1, 'html')
          return 
   end
 end
   	if text:match("[\216-\219][\128-\191]") then
      if database:get('bot:arabic:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
        if database:get('bot:arabic:ban'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send Arabic in Group</code>\n<b>The Block</b>", 1, 'html')
          return 
   end
   
        if database:get('bot:arabic:warn'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't Arabic in Group</code>", 1, 'html')
          return 
   end
 end
   	  if text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
      if database:get('bot:english:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	  end
	          if database:get('bot:english:ban'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
       chat_kick(msg.chat_id_, msg.sender_user_id_)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send English in Group</code>\n<b>The Block</b>", 1, 'html')
          return 
   end
   
        if database:get('bot:english:warn'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
    local user_id = msg.sender_user_id_
       delete_msg(chat,msgs)
          send(msg.chat_id_, 0, 1, "<b>Your ID : </b><i>"..msg.sender_user_id_.."</i>\n<code>Don't send English in Group</code>", 1, 'html')
          return 
   end
     end
    end
   end
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  ---------------------------******** END MSG CHECKS ********--------------------------------------------
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  if database:get('bot:cmds'..msg.chat_id_) and not is_mod(msg.sender_user_id_, msg.chat_id_) then
  return 
  else
    ------------------------------------ With Pattern -------------------------------------------
	if text:match("^[#!/]ping$") then
	   send(msg.chat_id_, msg.id_, 1, '_Pong_', 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[!/#]leave$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	     chat_leave(msg.chat_id_, bot_id)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Ee][Tt][Mm][Oo][Tt][Ee]$") and is_owner(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function promote_by_reply(extra, result, success)
	local hash = 'bot:mods:'..msg.chat_id_
	if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is Already moderator._', 1, 'md')
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _promoted as moderator._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,promote_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Ee][Tt][Mm][Oo][Tt][Ee] @(.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([Ss][Ee][Tt][Mm][Oo][Tt][Ee]) @(.*)$")} 
	function promote_by_username(extra, result, success)
	if result.id_ then
	        database:sadd('bot:mods:'..msg.chat_id_, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>promoted as moderator.!</b>'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],promote_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Ee][Tt][Mm][Oo][Tt][Ee] (%d+)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([Ss][Ee][Tt][Mm][Oo][Tt][Ee]) (%d+)$")} 	
	        database:sadd('bot:mods:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _promoted as moderator._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Rr][Ee][Mm][Mm][Oo][Tt][Ee]$") and is_owner(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function demote_by_reply(extra, result, success)
	local hash = 'bot:mods:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is not Promoted._', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Demoted._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,demote_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Rr][Ee][Mm][Mm][Oo][Tt][Ee] @(.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:mods:'..msg.chat_id_
	local ap = {string.match(text, "^[#/!]([Rr][Ee][Mm][Mm][Oo][Tt][Ee]) @(.*)$")} 
	function demote_by_username(extra, result, success)
	if result.id_ then
         database:srem(hash, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Demoted</b>'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],demote_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Rr][Ee][Mm][Mm][Oo][Tt][Ee] (%d+)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:mods:'..msg.chat_id_
	local ap = {string.match(text, "^[#/!]([Rr][Ee][Mm][Mm][Oo][Tt][Ee]) (%d+)$")} 	
         database:srem(hash, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Demoted._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Bb][Aa][Nn]$") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function ban_by_reply(extra, result, success)
	local hash = 'bot:banned:'..msg.chat_id_
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t [Kick/Ban] Moderators!!*', 1, 'md')
    else
    if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is Already Banned._', 1, 'md')
		 chat_kick(result.chat_id_, result.sender_user_id_)
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Banned._', 1, 'md')
		 chat_kick(result.chat_id_, result.sender_user_id_)
	end
    end
	end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,ban_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Bb][Aa][Nn] @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([Bb][Aa][Nn]) @(.*)$")} 
	function ban_by_username(extra, result, success)
	if result.id_ then
	if is_mod(result.id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t [Kick/Ban] Moderators!!*', 1, 'md')
    else
	        database:sadd('bot:banned:'..msg.chat_id_, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Banned.!</b>'
		 chat_kick(msg.chat_id_, result.id_)
	end
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],ban_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Bb][Aa][Nn] (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([Bb][Aa][Nn]) (%d+)$")}
	if is_mod(ap[2], msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t [Kick/Ban] Moderators!!*', 1, 'md')
    else
	        database:sadd('bot:banned:'..msg.chat_id_, ap[2])
		 chat_kick(msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Banned._', 1, 'md')
	end
end
  ----------------------------------------------unban--------------------------------------------
  	if text:match("^[#!/][Uu][Nn][Bb][Aa][Nn]$") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function unban_by_reply(extra, result, success)
	local hash = 'bot:banned:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is not Banned._', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Unbanned._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,unban_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Uu][Nn][Bb][Aa][Nn] @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([Uu][Nn][Bb][Aa][Nn]) @(.*)$")} 
	function unban_by_username(extra, result, success)
	if result.id_ then
         database:srem('bot:banned:'..msg.chat_id_, result.id_)
            text = '<b>User </b><code>'..result.id_..'</code> <b>Unbanned.!</b>'
            else 
            text = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	      resolve_username(ap[2],unban_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Uu][Nn][Bb][Aa][Nn] (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([Uu][Nn][Bb][Aa][Nn]) (%d+)$")} 	
	        database:srem('bot:banned:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Unbanned._', 1, 'md')
  end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]delall$") and is_owner(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function delall_by_reply(extra, result, success)
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t Delete Msgs from Moderators!!*', 1, 'md')
    else
         send(msg.chat_id_, msg.id_, 1, '_All Msgs from _ *'..result.sender_user_id_..'* _Has been deleted!!_', 1, 'md')
		     del_all_msgs(result.chat_id_, result.sender_user_id_)
    end
	end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,delall_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]delall (%d+)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
		local ass = {string.match(text, "^[#/!](delall) (%d+)$")} 
	if is_mod(ass[2], msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t Delete Msgs from Moderators!!*', 1, 'md')
    else
	 		     del_all_msgs(msg.chat_id_, ass[2])
         send(msg.chat_id_, msg.id_, 1, '<b>All Msg From user</b> <code>'..ass[2]..'</code> <b>Deleted!</b>', 1, 'html')
    end
	end
 -----------------------------------------------------------------------------------------------
	if text:match("^[#!/]delall @(.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](delall) @(.*)$")} 
	function delall_by_username(extra, result, success)
	if result.id_ then
	if is_mod(result.id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t Delete Msgs from Moderators!!*', 1, 'md')
		 return false
    end
		 		     del_all_msgs(msg.chat_id_, result.id_)
            text = '<b>All Msg From user</b> <code>'..result.id_..'</code> <b>Deleted!</b>'
            else 
            text = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	      resolve_username(ap[2],delall_by_username)
    end
  -----------------------------------------banall--------------------------------------------------
          if text:match("^[#!/][Bb][Aa][Nn][Aa][Ll][Ll] @(.*)$") and is_sudo(msg) then
            local ap = {string.match(text, "^[#!/]([Bb][Aa][Nn][Aa][Ll][Ll]) @(.*)$")}
            function banall_by_username(extra, result, success)
	if result.id_ then
    if database:sismember('bot:gbanned:', result.id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.id_..'* _is Already Banned all._', 1, 'md')
                                   chat_kick(msg.chat_id_, result.id_)
	else
         database:sadd('bot:gbanned:', result.id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.id_..'* _Banall Groups_', 1, 'md')
                                   chat_kick(msg.chat_id_, result.id_)
                                   end
                else
                  texts = '<code>User not found!</code>'
end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
end
            resolve_username(ap[2],banall_by_username)
          end

          if text:match("^[#!/][Bb][Aa][Nn][Aa][Ll][Ll] (%d+)$") and is_sudo(msg) then
            local ap = {string.match(text, "^[#!/]([Bb][Aa][Nn][Aa][Ll][Ll]) (%d+)$")}
            if not database:sismember("botadmins:", ap[2]) or sudo_users == result.sender_user_id_ then
	         	database:sadd('bot:gbanned:', ap[2])
              chat_kick(msg.chat_id_, ap[2])
                text = '<b>User :</b> <code>'..ap[2]..'</code> <b> Has been Globally Banned !</b>'
            else
                  text = '<b>User not found!</b>'
end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
            end

          if text:match("^[#!/][Bb][Aa][Nn][Aa][Ll][Ll]$") and is_sudo(msg) then
            function banall_by_reply(extra, result, success)
                database:sadd('bot:gbanned:', result.sender_user_id_)
                  text = '<b>User :</b> '..get_info(result.sender_user_id_)..' <b>Has been Globally Banned !</b>'
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
                chat_kick(result.chat_id_, result.id_)
              end
            tdcli.getMessage(msg.chat_id_, msg.reply_to_message_id_,banall_by_reply)
          end
  -----------------------------------------unbanall------------------------------------------------
          if text:match("^[#!/][Uu][Nn][Bb][Aa][Nn][Aa][Ll][Ll] @(.*)$") and is_sudo(msg) then
            local ap = {string.match(text, "^[#!/]([Uu][Nn][Bb][Aa][Nn][Aa][Ll][Ll]) @(.*)$")}
            function unbanall_by_username(extra, result, success)
              if result.id_ then
                database:srem('bot:gbanned:', result.id_)
                  text = '<b>User :</b> '..get_info(result.id_)..' <b>Has been Globally Unbanned !</b>'
              else
                  text = '<b>User not found!</b>'
              end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
            end
            resolve_username(ap[2],unbanall_by_username)
          end
-----------------------------------------id ------------------------------------------

          if text:match("^[#!/][Uu][Nn][Bb][Aa][Nn][Aa][Ll][Ll] (%d+)$") and is_sudo(msg) then
            local ap = {string.match(text, "^[#!/]([Uu][Nn][Bb][Aa][Nn][Aa][Ll][Ll]) (%d+)$")}
            if ap[2] then
                database:srem('bot:gbanned:', ap[2])
              text = '<b>User :</b> '..(ap[2])..' <b>Has been Globally Unbanned !</b>'
              else
                  text = '<b>User not found!</b>'
              end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
          end
-------------------------------------reply-----------------------------------------------

          if text:match("^[#!/][Uu][Nn][Bb][Aa][Nn][Aa][Ll][Ll]$") and is_sudo(msg) and msg.reply_to_message_id_ then
            function unbanall_by_reply(extra, result, success)
              if not database:sismember('bot:gbanned:', result.sender_user_id_) then
                  text = '<b>User :</b> '..get_info(result.sender_user_id_)..' <b>is Not Globally Banned !</b>'
                  else
             database:srem('bot:gbanned:', result.sender_user_id_)
                  text = '<b>User :</b> '..get_info(result.sender_user_id_)..' <b>Has been Globally Unbanned !</b>'
                  end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
              end
            getMessage(msg.chat_id_, msg.reply_to_message_id_,unbanall_by_reply)
          end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Ii][Ll][Ee][Nn][Tt]$") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function mute_by_reply(extra, result, success)
	local hash = 'bot:muted:'..msg.chat_id_
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t [silent] Moderators!!*', 1, 'md')
    else
    if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is Already silent._', 1, 'md')
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _silent_', 1, 'md')
	end
    end
	end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,mute_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Ii][Ll][Ee][Nn][Tt] @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([Ss][Ii][Ll][Ee][Nn][Tt]) @(.*)$")} 
	function mute_by_username(extra, result, success)
	if result.id_ then
	if is_mod(result.id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t [silent] Moderators!!*', 1, 'md')
    else
	        database:sadd('bot:muted:'..msg.chat_id_, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>silent</b>'
		 chat_kick(msg.chat_id_, result.id_)
	end
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],mute_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Ii][Ll][Ee][Nn][Tt] (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([Ss][Ii][Ll][Ee][Nn][Tt]) (%d+)$")}
	if is_mod(ap[2], msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t [silent] Moderators!!*', 1, 'md')
    else
	        database:sadd('bot:muted:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _silent_', 1, 'md')
	end
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Uu][Nn][Ss][Ii][Ll][Ee][Nn][Tt]$") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function unmute_by_reply(extra, result, success)
	local hash = 'bot:muted:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is not silent._', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _unsilent_', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,unmute_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Uu][Nn][Ss][Ii][Ll][Ee][Nn][Tt] @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([Uu][Nn][Ss][Ii][Ll][Ee][Nn][Tt]) @(.*)$")} 
	function unmute_by_username(extra, result, success)
	if result.id_ then
         database:srem('bot:muted:'..msg.chat_id_, result.id_)
            text = '<b>User </b><code>'..result.id_..'</code> <b>unsilent.!</b>'
            else 
            text = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	      resolve_username(ap[2],unmute_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Uu][Nn][Ss][Ii][Ll][Ee][Nn][Tt] (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([Uu][Nn][Ss][Ii][Ll][Ee][Nn][Tt]) (%d+)$")} 	
	        database:srem('bot:muted:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _unsilent_', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Ee][Tt][Oo][Ww][Nn][Ee][Rr]$") and is_admin(msg.sender_user_id_) and msg.reply_to_message_id_ then
	function setowner_by_reply(extra, result, success)
	local hash = 'bot:owners:'..msg.chat_id_
	if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is Already Owner._', 1, 'md')
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Promoted as Group Owner._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,setowner_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Ee][Tt][Oo][Ww][Nn][Ee][Rr] @(.*)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([Ss][Ee][Tt][Oo][Ww][Nn][Ee][Rr]) @(.*)$")} 
	function setowner_by_username(extra, result, success)
	if result.id_ then
	        database:sadd('bot:owners:'..msg.chat_id_, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Promoted as Group Owner.!</b>'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],setowner_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Ee][Tt][Oo][Ww][Nn][Ee][Rr] (%d+)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!]([Ss][Ee][Tt][Oo][Ww][Nn][Ee][Rr]) (%d+)$")} 	
	        database:sadd('bot:owners:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Promoted as Group Owner._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Rr][Ee][Mm][Oo][Ww][Nn][Ee][Rr]$") and is_admin(msg.sender_user_id_) and msg.reply_to_message_id_ then
	function deowner_by_reply(extra, result, success)
	local hash = 'bot:owners:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is not Owner._', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Removed from ownerlist._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,deowner_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Rr][Ee][Mm][Oo][Ww][Nn][Ee][Rr] @(.*)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:owners:'..msg.chat_id_
	local ap = {string.match(text, "^[#/!]([Rr][Ee][Mm][Oo][Ww][Nn][Ee][Rr]) @(.*)$")} 
	function remowner_by_username(extra, result, success)
	if result.id_ then
         database:srem(hash, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Removed from ownerlist</b>'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],remowner_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Rr][Ee][Mm][Oo][Ww][Nn][Ee][Rr] (%d+)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:owners:'..msg.chat_id_
	local ap = {string.match(text, "^[#/!]([Rr][Ee][Mm][Oo][Ww][Nn][Ee][Rr]) (%d+)$")} 	
         database:srem(hash, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Removed from ownerlist._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Ee][Tt][Aa][Dd][Mm][Ii][Nn]$") and is_sudo(msg) and msg.reply_to_message_id_ then
	function addadmin_by_reply(extra, result, success)
	local hash = 'bot:admins:'
	if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is Already Admin._', 1, 'md')
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Added to admins._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,addadmin_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Ee][Tt][Aa][Dd][Mm][Ii][Nn] @(.*)$") and is_sudo(msg) then
	local ap = {string.match(text, "^[#/!]([Ss][Ee][Tt][Aa][Dd][Mm][Ii][Nn]) @(.*)$")} 
	function addadmin_by_username(extra, result, success)
	if result.id_ then
	        database:sadd('bot:admins:', result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Added to admins.!</b>'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],addadmin_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Ee][Tt][Aa][Dd][Mm][Ii][Nn] (%d+)$") and is_sudo(msg) then
	local ap = {string.match(text, "^[#/!]([Ss][Ee][Tt][Aa][Dd][Mm][Ii][Nn]) (%d+)$")} 	
	        database:sadd('bot:admins:', ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Added to admins._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Rr][Ee][Mm][Aa][Dd][Mm][Ii][Nn]$") and is_sudo(msg) and msg.reply_to_message_id_ then
	function deadmin_by_reply(extra, result, success)
	local hash = 'bot:admins:'
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is not Admin._', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Removed from Admins!._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,deadmin_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Rr][Ee][Mm][Aa][Dd][Mm][Ii][Nn] @(.*)$") and is_sudo(msg) then
	local hash = 'bot:admins:'
	local ap = {string.match(text, "^[#/!]([Rr][Ee][Mm][Aa][Dd][Mm][Ii][Nn]) @(.*)$")} 
	function remadmin_by_username(extra, result, success)
	if result.id_ then
         database:srem(hash, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Removed from Admins!</b>'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],remadmin_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Rr][Ee][Mm][Aa][Dd][Mm][Ii][Nn] (%d+)$") and is_sudo(msg) then
	local hash = 'bot:admins:'
	local ap = {string.match(text, "^[#/!]([Rr][Ee][Mm][Aa][Dd][Mm][Ii][Nn]) (%d+)$")} 	
         database:srem(hash, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* Removed from Admins!_', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Mm][Oo][Dd][Ll][Ii][Ss][Tt]") and is_mod(msg.sender_user_id_, msg.chat_id_) then
    local hash =  'bot:mods:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "<b>Mod List:</b>\n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
                text = "<b>Mod List is empty !</b>"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Ii][Ll][Ee][Nn][Tt][Ll][Ii][Ss][Tt]") and is_mod(msg.sender_user_id_, msg.chat_id_) then
    local hash =  'bot:muted:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "<b>silent List:</b>\n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
                text = "<b>Silent List is empty !</b>"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Oo][Ww][Nn][Ee][Rr][Ss]$") or text:match("^[#!/][Oo][Ww][Nn][Ee][Rr][Ll][Ii][Ss][Tt]$") and is_sudo(msg) then
    local hash =  'bot:owners:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "<b>Owner List:</b>\n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
                text = "<b>Owner List is empty !</b>"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Bb][Aa][Nn][Ll][Ii][Ss][Tt]$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
    local hash =  'bot:banned:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "<b>Ban List:</b>\n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
                text = "<b>Ban List is empty !</b>"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
end

  if msg.content_.text_:match("^[#!/][Gg][Bb][Aa][Nn][Ll][Ii][Ss][Tt]$") and is_sudo(msg) then
    local hash =  'bot:gbanned:'
    local list = database:smembers(hash)
    local text = "<b>Global Ban List:</b>\n\n"
    for k,v in pairs(list) do
    local user_info = database:hgetall('user:'..v)
    if user_info and user_info.username then
    local username = user_info.username
      text = text..k.." - @"..username.." ["..v.."]\n"
      else
      text = text..k.." - "..v.."\n"
          end
end
            if #list == 0 then
                text = "<b>Banall List is empty !</b>"
            end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
          end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Aa][Dd][Mm][Ii][Nn][Ll][Ii][Ss][Tt]$") and is_sudo(msg) then
    local hash =  'bot:admins:'
	local list = database:smembers(hash)
	local text = "<b>Bot Admins :</b> \n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
                text = "<b>Admin List is empty !</b>"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
    if text:match("^[#!/][Ii][Dd]$") and msg.reply_to_message_id_ ~= 0 then
      function id_by_reply(extra, result, success)
	  local user_msgs = database:get('user:msgs'..result.chat_id_..':'..result.sender_user_id_)
        send(msg.chat_id_, msg.id_, 1, "`"..result.sender_user_id_.."`", 1, 'md')
        end
   getMessage(msg.chat_id_, msg.reply_to_message_id_,id_by_reply)
  end
  -----------------------------------------------------------------------------------------------
    if text:match("^[#!/][Ii][Dd] @(.*)$") then
	local ap = {string.match(text, "^[#/!]([Ii][Dd]) @(.*)$")} 
	function id_by_username(extra, result, success)
	if result.id_ then
            texts = '`'..result.id_..'`'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'md')
    end
	      resolve_username(ap[2],id_by_username)
    end
    
    if text:match("^[#!/][Rr][Ee][Ss] @(.*)$") then
	local ap = {string.match(text, "^[#/!]([Rr][Ee][Ss]) @(.*)$")} 
	function id_by_username(extra, result, success)
	if result.id_ then
            texts = '*> Username* : @'..ap[2]..'\n*> ID* : `'..result.id_..'`'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'md')
    end
	      resolve_username(ap[2],id_by_username)
    end
    -----------------------------------------------------------------------------------------------
  if text:match("^[#!/][Kk][Ii][Cc][Kk]$") and msg.reply_to_message_id_ and is_mod(msg.sender_user_id_, msg.chat_id_) then
      function kick_reply(extra, result, success)
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t [Kick/Ban] Moderators!!*', 1, 'md')
    else
        send(msg.chat_id_, msg.id_, 1, 'User '..result.sender_user_id_..' Kicked.', 1, 'html')
        chat_kick(result.chat_id_, result.sender_user_id_)
        end
	end
   getMessage(msg.chat_id_,msg.reply_to_message_id_,kick_reply)
  end
    -----------------------------------------------------------------------------------------------
  if text:match("^[#!/]inv$") and msg.reply_to_message_id_ and is_sudo(msg) then
      function inv_reply(extra, result, success)
           add_user(result.chat_id_, result.sender_user_id_, 5)
        end
   getMessage(msg.chat_id_, msg.reply_to_message_id_,inv_reply)
    end
	-----------------------------------------------------------------------------------------------
    if text:match("^[#!/]getpro (%d+)$") and msg.reply_to_message_id_ == 0  then
		local pronumb = {string.match(text, "^[#/!](getpro) (%d+)$")} 
local function gpro(extra, result, success)
--vardump(result)
   if pronumb[2] == '1' then
   if result.photos_[0] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '2' then
   if result.photos_[1] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[1].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 2 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '3' then
   if result.photos_[2] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[2].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 3 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '4' then
      if result.photos_[3] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[3].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 4 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '5' then
   if result.photos_[4] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[4].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 5 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '6' then
   if result.photos_[5] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[5].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 6 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '7' then
   if result.photos_[6] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[6].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 7 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '8' then
   if result.photos_[7] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[7].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 8 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '9' then
   if result.photos_[8] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[8].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 9 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '10' then
   if result.photos_[9] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[9].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "_You Have'nt 10 Profile Photo!!_", 1, 'md')
   end
   else
      send(msg.chat_id_, msg.id_, 1, "*I just can get last 10 profile photos!:(*", 1, 'md')
   end
   end
   tdcli_function ({
    ID = "GetUserProfilePhotos",
    user_id_ = msg.sender_user_id_,
    offset_ = 0,
    limit_ = pronumb[2]
  }, gpro, nil)
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ll][Oo][Cc][Kk] (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local lockpt = {string.match(text, "^[#/!]([Ll][Oo][Cc][Kk]) (.*)$")} 
    if lockpt[2] == "edit" then
         database:set('editmsg'..msg.chat_id_,'delmsg')
  send(msg.chat_id_, msg.id_, 1, "_> Edit Has been_ *locked*", 1, 'md')
   end
   if lockpt[2] == "bots" then
 if not database:get('bot:bots:mute'..msg.chat_id_) then
       send(msg.chat_id_, msg.id_, 1, "_> Bots Has been_ *locked*", 1, 'md')
   database:set('bot:bots:mute'..msg.chat_id_,true)
    else
   send(msg.chat_id_, msg.id_, 1, "_> Bots is Already_ *locked*", 1, 'md')
   end
     end
    if lockpt[2] == "flood ban" then
  send(msg.chat_id_, msg.id_, 1, '*Flood Ban* has been *locked*', 1, 'md')
         database:del('anti-flood:'..msg.chat_id_)
        end
   if lockpt[2] == "flood mute" then
      send(msg.chat_id_, msg.id_, 1, '*Flood Mute* has been *locked*', 1, 'md')
            database:del('anti-flood:warn'..msg.chat_id_)
	        end
        if lockpt[2] == "pin" and is_owner(msg.sender_user_id_, msg.chat_id_) then
        if not database:get('bot:pin:mute'..msg.chat_id_)  then
            send(msg.chat_id_, msg.id_, 1, "_> Pin Has been_ *locked*", 1, 'md')
          database:set('bot:pin:mute'..msg.chat_id_,true)
          else
            send(msg.chat_id_, msg.id_, 1, "_> Pin is Already_ *locked*", 1, 'md')
        end
        end
	   if lockpt[2] == "pin warn" and is_owner(msg.sender_user_id_, msg.chat_id_) then
	   if not database:get('bot:pin:warn'..msg.chat_id_)  then
         send(msg.chat_id_, msg.id_, 1, "_> Pin Warn Has been_ *locked*", 1, 'md')
	       database:set('bot:pin:warn'..msg.chat_id_,true)
       else
                            send(msg.chat_id_, msg.id_, 1, "_> Pin warn is Already_ *locked*", 1, 'md')
                   end
      end
              end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ff][Ll][Oo][Oo][Dd] [Bb][Aa][Nn] (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local floodmax = {string.match(text, "^[#/!]([Ff][Ll][Oo][Oo][Dd] [Bb][Aa][Nn]) (%d+)$")} 
	if tonumber(floodmax[2]) < 2 then
         send(msg.chat_id_, msg.id_, 1, '*Wrong number*,_range is  [2-99999]_', 1, 'md')
	else
    database:set('flood:max:'..msg.chat_id_,floodmax[2])
         send(msg.chat_id_, msg.id_, 1, '_> Flood has been set to_ *'..floodmax[2]..'*', 1, 'md')
	end
end

	if text:match("^[#!/][Ff][Ll][Oo][Oo][Dd] [Mm][Uu][Tt][Ee] (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local floodmax = {string.match(text, "^[#/!]([Ff][Ll][Oo][Oo][Dd] [Mm][Uu][Tt][Ee]) (%d+)$")} 
	if tonumber(floodmax[2]) < 2 then
         send(msg.chat_id_, msg.id_, 1, '*Wrong number*,_range is  [2-99999]_', 1, 'md')
	else
    database:set('flood:max:warn'..msg.chat_id_,floodmax[2])
         send(msg.chat_id_, msg.id_, 1, '_> Flood Warn has been set to_ *'..floodmax[2]..'*', 1, 'md')
	end
end

if text:match("^[#!/][Ss][Pp][Aa][Mm] [Dd][Ee][Ll] (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
local sensspam = {string.match(text, "^[#!/]([Ss][Pp][Aa][Mm] [Dd][Ee][Ll]) (%d+)$")}
if tonumber(sensspam[2]) < 40 then
send(msg.chat_id_, msg.id_, 1, '*Wrong number*,_range is  [40-99999]_', 1, 'md')
 else
database:set('bot:sens:spam'..msg.chat_id_,sensspam[2])
send(msg.chat_id_, msg.id_, 1, '_> Spam has been set to_ *'..sensspam[2]..'*', 1, 'md')
end
end

if text:match("^[#!/][Ss][Pp][Aa][Mm] [Ww][Aa][Rr][Nn] (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
local sensspam = {string.match(text, "^[#!/]([Ss][Pp][Aa][Mm] [Ww][Aa][Rr][Nn]) (%d+)$")}
if tonumber(sensspam[2]) < 40 then
send(msg.chat_id_, msg.id_, 1, '*Wrong number*,_range is  [40-99999]_', 1, 'md')
 else
database:set('bot:sens:spam:warn'..msg.chat_id_,sensspam[2])
send(msg.chat_id_, msg.id_, 1, '_> Spam Warn has been set to_ *'..sensspam[2]..'*', 1, 'md')
end
end

if text:match("^[#!/][Ss][Pp][Aa][Mm] [Bb][Aa][Nn] (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
local sensspam = {string.match(text, "^[#!/]([Ss][Pp][Aa][Mm] [Bb][Aa][Nn]) (%d+)$")}
if tonumber(sensspam[2]) < 40 then
send(msg.chat_id_, msg.id_, 1, '*Wrong number*,_range is  [40-99999]_', 1, 'md')
 else
database:set('bot:sens:spam:ban'..msg.chat_id_,sensspam[2])
send(msg.chat_id_, msg.id_, 1, '_> Spam ban has been set to_ *'..sensspam[2]..'*', 1, 'md')
end
end

	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ff][Ll][Oo][Oo][Dd] [Tt][Ii][Mm][Ee] (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local floodt = {string.match(text, "^[#/!]([Ff][Ll][Oo][Oo][Dd] [Tt][Ii][Mm][Ee]) (%d+)$")} 
	if tonumber(floodt[2]) < 2 then
         send(msg.chat_id_, msg.id_, 1, '*Wrong number*,_range is  [2-99999]_', 1, 'md')
	else
    database:set('flood:time:'..msg.chat_id_,floodt[2])
         send(msg.chat_id_, msg.id_, 1, '_> Flood has been set to_ *'..floodt[2]..'*', 1, 'md')
	end
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Hh][Oo][Ww] [Ee][Dd][Ii][Tt]$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*Done*\n_Activation detection has been activated_', 1, 'md')
         database:set('editmsg'..msg.chat_id_,'didam')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Ee][Tt][Ll][Ii][Nn][Kk]") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*Please Send Group Link Now!*', 1, 'md')
         database:set("bot:group:link"..msg.chat_id_, 'Waiting For Link!\nPls Send Group Link')
	end

  if text and text:match('[#!/][Ll][Ii][Nn][Kk] (.*)') then
        local link = text:match('[#!/][Ll][Ii][Nn][Kk] (.*)')
        database:set("bot:group:link"..msg.chat_id_, link)
                 send(msg.chat_id_, msg.id_, 1, '<b>Group link:</b>\n'..link, 1, 'html')
 	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ll][Ii][Nn][Kk]$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local link = database:get("bot:group:link"..msg.chat_id_)
	  if link then
         send(msg.chat_id_, msg.id_, 1, '<b>Group link:</b>\n'..link, 1, 'html')
	  else
         send(msg.chat_id_, msg.id_, 1, '*There is not link set yet. Please add one by #setlink .*', 1, 'md')
	  end
 	end
	
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ww][Ll][Cc] [Oo][Nn]$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '#Done\nWelcome *Enabled* In This Supergroup.', 1, 'md')
		 database:set("bot:welcome"..msg.chat_id_,true)
	end
	if text:match("^[#!/][Ww][Ll][Cc] [Oo][Ff][Ff]$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '#Done\nWelcome *Disabled* In This Supergroup.', 1, 'md')
		 database:del("bot:welcome"..msg.chat_id_)
	end
	if text:match("^[#!/][Ss][Ee][Tt] [Ww][Ll][Cc] (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local welcome = {string.match(text, "^[#/!]([Ss][Ee][Tt] [Ww][Ll][Cc]) (.*)$")} 
         send(msg.chat_id_, msg.id_, 1, '*Welcome Msg Has Been Saved!*\nWlc Text:\n\n`'..welcome[2]..'`', 1, 'md')
		 database:set('welcome:'..msg.chat_id_,welcome[2])
	end
	if text:match("^[#!/][Dd][Ee][Ll] [Ww][Ll][Cc]$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*Welcome Msg Has Been Deleted!*', 1, 'md')
		 database:del('welcome:'..msg.chat_id_)
	end
	if text:match("^[#!/][Gg][Ee][Tt] [Ww][Ll][Cc]$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local wel = database:get('welcome:'..msg.chat_id_)
	if wel then
         send(msg.chat_id_, msg.id_, 1, wel, 1, 'md')
    else
         send(msg.chat_id_, msg.id_, 1, 'Welcome msg not saved!', 1, 'md')
	end
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]action (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local lockpt = {string.match(text, "^[#/!](action) (.*)$")} 
      if lockpt[2] == "typing" then
          sendaction(msg.chat_id_, 'Typing')
	  end
	  if lockpt[2] == "video" then
          sendaction(msg.chat_id_, 'RecordVideo')
	  end
	  if lockpt[2] == "voice" then
          sendaction(msg.chat_id_, 'RecordVoice')
	  end
	  if lockpt[2] == "photo" then
          sendaction(msg.chat_id_, 'UploadPhoto')
	  end
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Bb][Aa][Dd] (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local filters = {string.match(text, "^[#/!]([Bb][Aa][Dd]) (.*)$")} 
    local name = string.sub(filters[2], 1, 50)
          database:hset('bot:filters:'..msg.chat_id_, name, 'filtered')
		  send(msg.chat_id_, msg.id_, 1, "*New Word baded!*\n--> `"..name.."`", 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Uu][Nn][Bb][Aa][Dd] (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local rws = {string.match(text, "^[#/!]([Uu][Nn][Bb][Aa][Dd]) (.*)$")} 
    local name = string.sub(rws[2], 1, 50)
          database:hdel('bot:filters:'..msg.chat_id_, rws[2])
		  send(msg.chat_id_, msg.id_, 1, "`"..rws[2].."` *Removed From baded List!*", 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Bb][Aa][Dd][Ll][Ii][Ss][Tt]$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:filters:'..msg.chat_id_
      if hash then
         local names = database:hkeys(hash)
         local text = '*baded Words :*\n\n'
    for i=1, #names do
      text = text..'> `'..names[i]..'`\n'
    end
	if #names == 0 then
       text = "*bad List is empty*"
    end
		  send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
       end
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]bc (.*)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
    local gps = database:scard("bot:groups") or 0
    local gpss = database:smembers("bot:groups") or 0
	local rws = {string.match(text, "^[#/!](bc) (.*)$")} 
	for i=1, #gpss do
		  send(gpss[i], 0, 1, rws[2], 1, 'md')
    end
                   send(msg.chat_id_, msg.id_, 1, '*Done*\n_Your Msg Send to_ `'..gps..'` _Groups_', 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Gg][Rr][Oo][Uu][Pp][Ss]$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
    local gps = database:scard("bot:groups")
	local users = database:scard("bot:userss")
    local allmgs = database:get("bot:allmsgs")
                   send(msg.chat_id_, msg.id_, 1, '*Groups :* `'..gps..'`', 1, 'md')
	end
	
if  text:match("^[/!#][Mm][Ss][Gg]$") and msg.reply_to_message_id_ == 0  then
local user_msgs = database:get('user:msgs'..msg.chat_id_..':'..msg.sender_user_id_)
      send(msg.chat_id_, msg.id_, 1, "*Msgs : * `"..user_msgs.."`", 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/][Uu][Nn][Ll][Oo][Cc][Kk] (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local unlockpt = {string.match(text, "^[#/!]([Uu][Nn][Ll][Oo][Cc][Kk]) (.*)$")} 
                if unlockpt[2] == "edit" then
                    send(msg.chat_id_, msg.id_, 1, "_> Edit Has been_ *Unlocked*", 1, 'md')
         database:del('editmsg'..msg.chat_id_)
      end
                if unlockpt[2] == "bots" then
                  if database:get('bot:bots:mute'..msg.chat_id_) then
                    send(msg.chat_id_, msg.id_, 1, "_> Bots Has been_ *Unlocked*", 1, 'md')
                    database:del('bot:bots:mute'..msg.chat_id_)
                  else
                    send(msg.chat_id_, msg.id_, 1, "_> Bots is Already_ *Unlocked*", 1, 'md')
                  end
                end
	              if unlockpt[2] == "flood ban" then
                   send(msg.chat_id_, msg.id_, 1, '*Flood Ban* has been *unlocked*', 1, 'md')
                   database:set('anti-flood:'..msg.chat_id_,true)
            	  end
            	  if unlockpt[2] == "flood mute" then
                    send(msg.chat_id_, msg.id_, 1, '*Flood Mute* has been *unlocked*', 1, 'md')
                    database:set('anti-flood:warn'..msg.chat_id_,true)
             	  end
                if unlockpt[2] == "pin" and is_owner(msg.sender_user_id_, msg.chat_id_) then
                  if database:get('bot:pin:mute'..msg.chat_id_)  then
                    send(msg.chat_id_, msg.id_, 1, "_> Pin Has been_ *Unlocked*", 1, 'md')
                    database:del('bot:pin:mute'..msg.chat_id_)
                  else
                    send(msg.chat_id_, msg.id_, 1, "_> Pin is Already_ *Unlocked*", 1, 'md')
                  end
              end
	               if unlockpt[2] == "pin warn" and is_owner(msg.sender_user_id_, msg.chat_id_) then
	               if database:get('bot:pin:warn'..msg.chat_id_)  then
                   send(msg.chat_id_, msg.id_, 1, "_> Pin Warn Has been_ *Unlocked*", 1, 'md')
	                 database:del('bot:pin:warn'..msg.chat_id_)
                 else
                            send(msg.chat_id_, msg.id_, 1, "_> Pin warn is Already_ *Unlocked*", 1, 'md')
                   end
      end
              end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/][Ll][Oo][Cc][Kk] [Aa][Ll][Ll] (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local mutept = {string.match(text, "^[#!/][Ll][Oo][Cc][Kk] [Aa][Ll][Ll] (%d+)$")}
	    		database:setex('bot:muteall'..msg.chat_id_, tonumber(mutept[1]), true)
         send(msg.chat_id_, msg.id_, 1, '_> Group muted for_ *'..mutept[1]..'* _seconds!_', 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/][Ll][Oo][Cc][Kk] (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local mutept = {string.match(text, "^[#/!]([Ll][Oo][Cc][Kk]) (.*)$")} 
      if mutept[2] == "all" then
	  if not database:get('bot:muteall'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> mute all has been_ *Locked*', 1, 'md')
         database:set('bot:muteall'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> mute all is already_ *Locked*', 1, 'md')
      end 
    end
      if mutept[2] == "all warn" then
	  if not database:get('bot:muteallwarn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> mute all warn has been_ *Locked*', 1, 'md')
         database:set('bot:muteallwarn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> mute all warn is already_ *Locked*', 1, 'md')
      end 
    end
      if mutept[2] == "all ban" then
	  if not database:get('bot:muteallban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> mute all ban has been_ *Locked*', 1, 'md')
         database:set('bot:muteallban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> mute all ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "text" then
	  if not database:get('bot:text:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> Text has been_ *Locked*', 1, 'md')
         database:set('bot:text:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> text is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "text ban" then
if not database:get('bot:text:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> text ban has been_ *Locked*', 1, 'md')
         database:set('bot:text:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> text ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "text warn" then
if not database:get('bot:text:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> text and warn has been_ *Locked*', 1, 'md')
         database:set('bot:text:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> text and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "inline" then
	  if not database:get('bot:inline:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> inline has been_ *Locked*', 1, 'md')
         database:set('bot:inline:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> inline is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "inline ban" then
if not database:get('bot:inline:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> inline ban has been_ *Locked*', 1, 'md')
         database:set('bot:inline:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> inline ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "inline warn" then
if not database:get('bot:inline:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> inline and warn has been_ *Locked*', 1, 'md')
         database:set('bot:inline:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> inline and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "photo" then
	  if not database:get('bot:photo:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> photo has been_ *Locked*', 1, 'md')
         database:set('bot:photo:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> photo is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "photo ban" then
if not database:get('bot:photo:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> photo ban has been_ *Locked*', 1, 'md')
         database:set('bot:photo:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> photo ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "photo warn" then
if not database:get('bot:photo:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> photo and warn has been_ *Locked*', 1, 'md')
         database:set('bot:photo:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> photo and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "video" then
	  if not database:get('bot:video:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> video has been_ *Locked*', 1, 'md')
         database:set('bot:video:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> video is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "video ban" then
if not database:get('bot:video:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> video ban has been_ *Locked*', 1, 'md')
         database:set('bot:video:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> video ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "video warn" then
if not database:get('bot:video:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> video and warn has been_ *Locked*', 1, 'md')
         database:set('bot:video:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> video and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "gif" then
	  if not database:get('bot:gifs:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> gifs has been_ *Locked*', 1, 'md')
         database:set('bot:gifs:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> gifs is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "gif ban" then
if not database:get('bot:gifs:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> gifs ban has been_ *Locked*', 1, 'md')
         database:set('bot:gifs:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> gifs ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "gif warn" then
if not database:get('bot:gifs:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> gifs and warn has been_ *Locked*', 1, 'md')
         database:set('bot:gifs:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> gifs and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "music" then
	  if not database:get('bot:music:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> music has been_ *Locked*', 1, 'md')
         database:set('bot:music:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> music is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "music ban" then
	  if not database:get('bot:music:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> music ban has been_ *Locked*', 1, 'md')
         database:set('bot:music:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> music ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "music warn" then
    if not database:get('bot:music:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> music and warn has been_ *Locked*', 1, 'md')
         database:set('bot:music:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> music and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "voice" then
	  if not database:get('bot:voice:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> voice has been_ *Locked*', 1, 'md')
         database:set('bot:voice:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> voice is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "voice ban" then
	  if not database:get('bot:voice:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> voice ban has been_ *Locked*', 1, 'md')
         database:set('bot:voice:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> voice ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "voice warn" then
	  if not database:get('bot:voice:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> voice and warn has been_ *Locked*', 1, 'md')
         database:set('bot:voice:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> voice and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "links" then
	  if not database:get('bot:links:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> links has been_ *Locked*', 1, 'md')
         database:set('bot:links:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> links is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "links ban" then
	  if not database:get('bot:links:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> links ban has been_ *Locked*', 1, 'md')
         database:set('bot:links:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> links ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "links warn" then
	  if not database:get('bot:links:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> links and warn has been_ *Locked*', 1, 'md')
         database:set('bot:links:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> links and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "location" then
	  if not database:get('bot:location:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> location has been_ *Locked*', 1, 'md')
         database:set('bot:location:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> location is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "location ban" then
	  if not database:get('bot:location:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> location ban has been_ *Locked*', 1, 'md')
         database:set('bot:location:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> location ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "location warn" then
	  if not database:get('bot:location:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> location and warn has been_ *Locked*', 1, 'md')
         database:set('bot:location:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> location and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "tag" then
	  if not database:get('bot:tag:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> tag has been_ *Locked*', 1, 'md')
         database:set('bot:tag:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> tag is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "tag ban" then
	  if not database:get('bot:tag:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> tag ban has been_ *Locked*', 1, 'md')
         database:set('bot:tag:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> tag ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "tag warn" then
	  if not database:get('bot:tag:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> tag and warn has been_ *Locked*', 1, 'md')
         database:set('bot:tag:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> tag and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "hashtag" then
	  if not database:get('bot:hashtag:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> hashtag has been_ *Locked*', 1, 'md')
         database:set('bot:hashtag:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> hashtag is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "hashtag ban" then
	  if not database:get('bot:hashtag:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> hashtag ban has been_ *Locked*', 1, 'md')
         database:set('bot:hashtag:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> hashtag ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "hashtag warn" then
	  if not database:get('bot:hashtag:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> hashtag and warn has been_ *Locked*', 1, 'md')
         database:set('bot:hashtag:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> hashtag and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "contact" then
	  if not database:get('bot:contact:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> contact has been_ *Locked*', 1, 'md')
         database:set('bot:contact:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> contact is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "contact ban" then
	  if not database:get('bot:contact:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> contact ban has been_ *Locked*', 1, 'md')
         database:set('bot:contact:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> contact ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "contact warn" then
	  if not database:get('bot:contact:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> contact and warn has been_ *Locked*', 1, 'md')
         database:set('bot:contact:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> contact and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "webpage" then
	  if not database:get('bot:webpage:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> webpage has been_ *Locked*', 1, 'md')
         database:set('bot:webpage:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> webpage is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "webpage ban" then
	  if not database:get('bot:webpage:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> webpage ban has been_ *Locked*', 1, 'md')
         database:set('bot:webpage:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> webpage ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "webpage warn" then
	  if not database:get('bot:webpage:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> webpage and warn has been_ *Locked*', 1, 'md')
         database:set('bot:webpage:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> webpage and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "arabic" then
	  if not database:get('bot:arabic:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> arabic has been_ *Locked*', 1, 'md')
         database:set('bot:arabic:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> arabic is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "arabic ban" then
	  if not database:get('bot:arabic:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> arabic ban has been_ *Locked*', 1, 'md')
         database:set('bot:arabic:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> arabic ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "arabic warn" then
	  if not database:get('bot:arabic:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> arabic and warn has been_ *Locked*', 1, 'md')
         database:set('bot:arabic:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> arabic and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "english" then
	  if not database:get('bot:english:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> english has been_ *Locked*', 1, 'md')
         database:set('bot:english:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> english is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "english ban" then
	  if not database:get('bot:english:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> english ban has been_ *Locked*', 1, 'md')
         database:set('bot:english:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> english ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "english warn" then
	  if not database:get('bot:english:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> english and warn has been_ *Locked*', 1, 'md')
         database:set('bot:english:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> english and warn is already_ *Locked*', 1, 'md')
      end 
      end
    if mutept[2] == "spam del" then
    if not database:get('bot:spam:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> Spam has been_ *Locked*', 1, 'md')
         database:set('bot:spam:mute'..msg.chat_id_,true)
       else
         send(msg.chat_id_, msg.id_, 1, '_> Spam is already_ *Locked*', 1, 'md')
    end
   end
    if mutept[2] == "spam warn" then
    if not database:get('bot:spam:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> Spam and Warn has been_ *Locked*', 1, 'md')
         database:set('bot:spam:warn'..msg.chat_id_,true)
       else
         send(msg.chat_id_, msg.id_, 1, '_> Spam and Warn is already_ *Locked*', 1, 'md')
    end
   end
    if mutept[2] == "spam ban" then
    if not database:get('bot:spam:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> Spam and ban has been_ *Locked*', 1, 'md')
         database:set('bot:spam:ban'..msg.chat_id_,true)
       else
         send(msg.chat_id_, msg.id_, 1, '_> Spam and ban is already_ *Locked*', 1, 'md')
    end
     end
	  if mutept[2] == "sticker" then
	  if not database:get('bot:sticker:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> Sticker has been_ *Locked*', 1, 'md')
         database:set('bot:sticker:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> Sticker is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "sticker ban" then
	  if not database:get('bot:sticker:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> Sticker ban has been_ *Locked*', 1, 'md')
         database:set('bot:sticker:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> Sticker ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "sticker warn" then
	  if not database:get('bot:sticker:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> Sticker and warn has been_ *Locked*', 1, 'md')
         database:set('bot:sticker:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> Sticker and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "service" then
	  if not database:get('bot:tgservice:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> tgservice has been_ *Locked*', 1, 'md')
         database:set('bot:tgservice:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> tgservice is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "fwd" then
	  if not database:get('bot:forward:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> forward has been_ *Locked*', 1, 'md')
         database:set('bot:forward:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> forward is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "fwd ban" then
	  if not database:get('bot:forward:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> forward ban has been_ *Locked*', 1, 'md')
         database:set('bot:forward:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> forward ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "fwd warn" then
	  if not database:get('bot:forward:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> forward and warn has been_ *Locked*', 1, 'md')
         database:set('bot:forward:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> forward and warn is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "cmd" then
	  if not database:get('bot:cmd:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> cmd has been_ *Locked*', 1, 'md')
         database:set('bot:cmd:mute'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> cmd is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "cmd ban" then
	  if not database:get('bot:cmd:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> cmd ban has been_ *Locked*', 1, 'md')
         database:set('bot:cmd:ban'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> cmd ban is already_ *Locked*', 1, 'md')
      end 
      end
	  if mutept[2] == "cmd warn" then
	  if not database:get('bot:cmd:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> cmd and warn has been_ *Locked*', 1, 'md')
         database:set('bot:cmd:warn'..msg.chat_id_,true)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> cmd and warn is already_ *Locked*', 1, 'md')
      end 
      end
	end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/][Uu][Nn][Ll][Oo][Cc][Kk] (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local unmutept = {string.match(text, "^[#/!]([Uu][Nn][Ll][Oo][Cc][Kk]) (.*)$")} 
      if unmutept[2] == "all" then
	  if database:get('bot:muteall'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> mute all has been_ *unLocked*', 1, 'md')
         database:del('bot:muteall'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> mute all is already_ *unLocked*', 1, 'md')
      end 
    end
      if unmutept[2] == "all warn" then
	  if database:get('bot:muteallwarn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> mute all warn has been_ *unLocked*', 1, 'md')
         database:del('bot:muteallwarn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> mute all warn is already_ *unLocked*', 1, 'md')
      end 
    end
      if unmutept[2] == "all ban" then
	  if database:get('bot:muteallban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> mute all ban has been_ *unLocked*', 1, 'md')
         database:del('bot:muteallban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> mute all ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "text" then
	  if database:get('bot:text:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> Text has been_ *unLocked*', 1, 'md')
         database:del('bot:text:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> text is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "text ban" then
if database:get('bot:text:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> text ban has been_ *unLocked*', 1, 'md')
         database:del('bot:text:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> text ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "text warn" then
if database:get('bot:text:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> text and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:text:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> text and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "inline" then
	  if database:get('bot:inline:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> inline has been_ *unLocked*', 1, 'md')
         database:del('bot:inline:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> inline is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "inline ban" then
if database:get('bot:inline:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> inline ban has been_ *unLocked*', 1, 'md')
         database:del('bot:inline:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> inline ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "inline warn" then
if database:get('bot:inline:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> inline and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:inline:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> inline and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "photo" then
	  if database:get('bot:photo:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> photo has been_ *unLocked*', 1, 'md')
         database:del('bot:photo:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> photo is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "photo ban" then
if database:get('bot:photo:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> photo ban has been_ *unLocked*', 1, 'md')
         database:del('bot:photo:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> photo ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "photo warn" then
if database:get('bot:photo:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> photo and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:photo:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> photo and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "video" then
	  if database:get('bot:video:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> video has been_ *unLocked*', 1, 'md')
         database:del('bot:video:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> video is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "video ban" then
if database:get('bot:video:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> video ban has been_ *unLocked*', 1, 'md')
         database:del('bot:video:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> video ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "video warn" then
if database:get('bot:video:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> video and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:video:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> video and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "gif" then
	  if database:get('bot:gifs:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> gifs has been_ *unLocked*', 1, 'md')
         database:del('bot:gifs:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> gifs is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "gif ban" then
if database:get('bot:gifs:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> gifs ban has been_ *unLocked*', 1, 'md')
         database:del('bot:gifs:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> gifs ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "gif warn" then
if database:get('bot:gifs:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> gifs and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:gifs:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> gifs and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "music" then
	  if database:get('bot:music:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> music has been_ *unLocked*', 1, 'md')
         database:del('bot:music:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> music is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "music ban" then
	  if database:get('bot:music:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> music ban has been_ *unLocked*', 1, 'md')
         database:del('bot:music:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> music ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "music warn" then
    if database:get('bot:music:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> music and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:music:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> music and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "voice" then
	  if database:get('bot:voice:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> voice has been_ *unLocked*', 1, 'md')
         database:del('bot:voice:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> voice is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "voice ban" then
	  if database:get('bot:voice:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> voice ban has been_ *unLocked*', 1, 'md')
         database:del('bot:voice:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> voice ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "voice warn" then
	  if database:get('bot:voice:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> voice and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:voice:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> voice and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "links" then
	  if database:get('bot:links:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> links has been_ *unLocked*', 1, 'md')
         database:del('bot:links:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> links is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "links ban" then
	  if database:get('bot:links:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> links ban has been_ *unLocked*', 1, 'md')
         database:del('bot:links:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> links ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "links warn" then
	  if database:get('bot:links:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> links and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:links:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> links and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "location" then
	  if database:get('bot:location:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> location has been_ *unLocked*', 1, 'md')
         database:del('bot:location:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> location is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "location ban" then
	  if database:get('bot:location:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> location ban has been_ *unLocked*', 1, 'md')
         database:del('bot:location:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> location ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "location warn" then
	  if database:get('bot:location:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> location and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:location:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> location and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "tag" then
	  if database:get('bot:tag:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> tag has been_ *unLocked*', 1, 'md')
         database:del('bot:tag:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> tag is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "tag ban" then
	  if database:get('bot:tag:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> tag ban has been_ *unLocked*', 1, 'md')
         database:del('bot:tag:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> tag ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "tag warn" then
	  if database:get('bot:tag:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> tag and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:tag:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> tag and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "hashtag" then
	  if database:get('bot:hashtag:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> hashtag has been_ *unLocked*', 1, 'md')
         database:del('bot:hashtag:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> hashtag is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "hashtag ban" then
	  if database:get('bot:hashtag:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> hashtag ban has been_ *unLocked*', 1, 'md')
         database:del('bot:hashtag:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> hashtag ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "hashtag warn" then
	  if database:get('bot:hashtag:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> hashtag and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:hashtag:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> hashtag and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "contact" then
	  if database:get('bot:contact:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> contact has been_ *unLocked*', 1, 'md')
         database:del('bot:contact:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> contact is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "contact ban" then
	  if database:get('bot:contact:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> contact ban has been_ *unLocked*', 1, 'md')
         database:del('bot:contact:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> contact ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "contact warn" then
	  if database:get('bot:contact:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> contact and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:contact:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> contact and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "webpage" then
	  if database:get('bot:webpage:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> webpage has been_ *unLocked*', 1, 'md')
         database:del('bot:webpage:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> webpage is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "webpage ban" then
	  if database:get('bot:webpage:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> webpage ban has been_ *unLocked*', 1, 'md')
         database:del('bot:webpage:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> webpage ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "webpage warn" then
	  if database:get('bot:webpage:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> webpage and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:webpage:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> webpage and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "arabic" then
	  if database:get('bot:arabic:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> arabic has been_ *unLocked*', 1, 'md')
         database:del('bot:arabic:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> arabic is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "arabic ban" then
	  if database:get('bot:arabic:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> arabic ban has been_ *unLocked*', 1, 'md')
         database:del('bot:arabic:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> arabic ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "arabic warn" then
	  if database:get('bot:arabic:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> arabic and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:arabic:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> arabic and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "english" then
	  if database:get('bot:english:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> english has been_ *unLocked*', 1, 'md')
         database:del('bot:english:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> english is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "english ban" then
	  if database:get('bot:english:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> english ban has been_ *unLocked*', 1, 'md')
         database:del('bot:english:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> english ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "english warn" then
	  if database:get('bot:english:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> english and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:english:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> english and warn is already_ *unLocked*', 1, 'md')
      end 
      end
    if unmutept[2] == "spam del" then
    if database:get('bot:spam:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> Spam has been_ *unLocked*', 1, 'md')
         database:del('bot:spam:mute'..msg.chat_id_)
       else
         send(msg.chat_id_, msg.id_, 1, '_> Spam is already_ *unLocked*', 1, 'md')
    end
   end
    if unmutept[2] == "spam warn" then
    if database:get('bot:spam:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> Spam and Warn has been_ *unLocked*', 1, 'md')
         database:del('bot:spam:warn'..msg.chat_id_)
       else
         send(msg.chat_id_, msg.id_, 1, '_> Spam and Warn is already_ *unLocked*', 1, 'md')
    end
   end
    if unmutept[2] == "spam ban" then
    if database:get('bot:spam:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> Spam and ban has been_ *unLocked*', 1, 'md')
         database:del('bot:spam:ban'..msg.chat_id_)
       else
         send(msg.chat_id_, msg.id_, 1, '_> Spam and ban is already_ *unLocked*', 1, 'md')
    end
     end
	  if unmutept[2] == "sticker" then
	  if database:get('bot:sticker:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> Sticker has been_ *unLocked*', 1, 'md')
         database:del('bot:sticker:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> Sticker is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "sticker ban" then
	  if database:get('bot:sticker:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> Sticker ban has been_ *unLocked*', 1, 'md')
         database:del('bot:sticker:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> Sticker ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "sticker warn" then
	  if database:get('bot:sticker:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> Sticker and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:sticker:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> Sticker and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "service" then
	  if database:get('bot:tgservice:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> tgservice has been_ *unLocked*', 1, 'md')
         database:del('bot:tgservice:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> tgservice is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "fwd" then
	  if database:get('bot:forward:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> forward has been_ *unLocked*', 1, 'md')
         database:del('bot:forward:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> forward is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "fwd ban" then
	  if database:get('bot:forward:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> forward ban has been_ *unLocked*', 1, 'md')
         database:del('bot:forward:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> forward ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "fwd warn" then
	  if database:get('bot:forward:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> forward and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:forward:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> forward and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "cmd" then
	  if database:get('bot:cmd:mute'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> cmd has been_ *unLocked*', 1, 'md')
         database:del('bot:cmd:mute'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> cmd is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "cmd ban" then
	  if database:get('bot:cmd:ban'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> cmd ban has been_ *unLocked*', 1, 'md')
         database:del('bot:cmd:ban'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> cmd ban is already_ *unLocked*', 1, 'md')
      end 
      end
	  if unmutept[2] == "cmd warn" then
	  if database:get('bot:cmd:warn'..msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_> cmd and warn has been_ *unLocked*', 1, 'md')
         database:del('bot:cmd:warn'..msg.chat_id_)
         else
                  send(msg.chat_id_, msg.id_, 1, '_> cmd and warn is already_ *unLocked*', 1, 'md')
      end 
      end
	end 
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]edit (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local editmsg = {string.match(text, "^[#/!](edit) (.*)$")} 
		 edit(msg.chat_id_, msg.reply_to_message_id_, nil, editmsg[2], 1, 'html')
		 	          send(msg.chat_id_, msg.id_, 1, '*Done* _Edit My Msg_', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
    if text:match("^[#!/][Cc][Ll][Ee][Aa][Nn] [Gg][Bb][Aa][Nn][Ll][Ii][Ss][Tt]$") and is_sudo(msg) then
      text = '_> Banall has been_ *Cleaned*'
      database:del('bot:gbanned:')
	    send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
  end

    if text:match("^[#!/][Cc][Ll][Ee][Aa][Nn] [Aa][Dd][Mm][Ii][Nn][Ss]$") and is_sudo(msg) then
      text = '_> adminlist has been_ *Cleaned*'
      database:del('bot:admins:')
	    send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
  end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/][Cc][Ll][Ee][Aa][Nn] (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[#!/]([Cc][Ll][Ee][Aa][Nn]) (.*)$")} 
       if txt[2] == 'banlist' or txt[2] == 'Banlist' then
	      database:del('bot:banned:'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '_> Banlist has been_ *Cleaned*', 1, 'md')
       end
	   if txt[2] == 'bots' or txt[2] == 'Bots' then
	  local function g_bots(extra,result,success)
      local bots = result.members_
      for i=0 , #bots do
          chat_kick(msg.chat_id_,bots[i].msg.sender_user_id_)
          end 
      end
    channel_get_bots(msg.chat_id_,g_bots) 
	          send(msg.chat_id_, msg.id_, 1, '_> All bots_ *kicked!*', 1, 'md')
	end
	   if txt[2] == 'modlist' or txt[2] == 'Modlist' and is_owner(msg.sender_user_id_, msg.chat_id_) then
	      database:del('bot:mods:'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '_> Modlist has been_ *Cleaned*', 1, 'md')
       end 
	   if txt[2] == 'owners' or txt[2] == 'Owners' and is_sudo(msg) then
	      database:del('bot:owners:'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '_> ownerlist has been_ *Cleaned*', 1, 'md')
       end
	   if txt[2] == 'rules' or txt[2] == 'Rules' then
	      database:del('bot:rules'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '_> rules has been_ *Cleaned*', 1, 'md')
       end
	   if txt[2] == 'link' or  txt[2] == 'Link' then
	      database:del('bot:group:link'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '_> link has been_ *Cleaned*', 1, 'md')
       end
	   if txt[2] == 'badlist' or txt[2] == 'Badlist' then
	      database:del('bot:filters:'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '_> badlist has been_ *Cleaned*', 1, 'md')
       end
	   if txt[2] == 'silentlist' or txt[2] == 'Silentlist' then
	      database:del('bot:muted:'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '_> silentlist has been_ *Cleaned*', 1, 'md')
       end
       
    end 
	-----------------------------------------------------------------------------------------------
  	 if text:match("^[/!][Ss] [Dd][Ee][Ll]$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	if database:get('bot:muteall'..msg.chat_id_) then
	mute_all = '`lock | 🔐`'
	else
	mute_all = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:text:mute'..msg.chat_id_) then
	mute_text = '`lock | 🔐`'
	else
	mute_text = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:photo:mute'..msg.chat_id_) then
	mute_photo = '`lock | 🔐`'
	else
	mute_photo = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:video:mute'..msg.chat_id_) then
	mute_video = '`lock | 🔐`'
	else
	mute_video = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:gifs:mute'..msg.chat_id_) then
	mute_gifs = '`lock | 🔐`'
	else
	mute_gifs = '`unlock | 🔓`'
	end
	------------
	if database:get('anti-flood:'..msg.chat_id_) then
	mute_flood = '`unlock | 🔓`'
	else  
	mute_flood = '`lock | 🔐`'
	end
	------------
	if not database:get('flood:max:'..msg.chat_id_) then
	flood_m = 5
	else
	flood_m = database:get('flood:max:'..msg.chat_id_)
end
	------------
	if not database:get('flood:time:'..msg.chat_id_) then
	flood_t = 3
	else
	flood_t = database:get('flood:time:'..msg.chat_id_)
	end
	------------
	if database:get('bot:music:mute'..msg.chat_id_) then
	mute_music = '`lock | 🔐`'
	else
	mute_music = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:bots:mute'..msg.chat_id_) then
	mute_bots = '`lock | 🔐`'
	else
	mute_bots = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:inline:mute'..msg.chat_id_) then
	mute_in = '`lock | 🔐`'
	else
	mute_in = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:voice:mute'..msg.chat_id_) then
	mute_voice = '`lock | 🔐`'
	else
	mute_voice = '`unlock | 🔓`'
	end
	------------
	if database:get('editmsg'..msg.chat_id_) then
	mute_edit = '`lock | 🔐`'
	else
	mute_edit = '`unlock | 🔓`'
	end
    ------------
	if database:get('bot:links:mute'..msg.chat_id_) then
	mute_links = '`lock | 🔐`'
	else
	mute_links = '`unlock | 🔓`'
	end
    ------------
	if database:get('bot:pin:mute'..msg.chat_id_) then
	lock_pin = '`lock | 🔐`'
	else
	lock_pin = '`unlock | 🔓`'
	end 
    ------------
	if database:get('bot:sticker:mute'..msg.chat_id_) then
	lock_sticker = '`lock | 🔐`'
	else
	lock_sticker = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:tgservice:mute'..msg.chat_id_) then
	lock_tgservice = '`lock | 🔐`'
	else
	lock_tgservice = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:webpage:mute'..msg.chat_id_) then
	lock_wp = '`lock | 🔐`'
	else
	lock_wp = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:hashtag:mute'..msg.chat_id_) then
	lock_htag = '`lock | 🔐`'
	else
	lock_htag = '`unlock | 🔓`'
end

   if database:get('bot:cmd:mute'..msg.chat_id_) then
	lock_cmd = '`lock | 🔐`'
	else
	lock_cmd = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:tag:mute'..msg.chat_id_) then
	lock_tag = '`lock | 🔐`'
	else
	lock_tag = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:location:mute'..msg.chat_id_) then
	lock_location = '`lock | 🔐`'
	else
	lock_location = '`unlock | 🔓`'
end
  ------------
if not database:get('bot:sens:spam'..msg.chat_id_) then
spam_c = 250
else
spam_c = database:get('bot:sens:spam'..msg.chat_id_)
end

if not database:get('bot:sens:spam:warn'..msg.chat_id_) then
spam_d = 250
else
spam_d = database:get('bot:sens:spam:warn'..msg.chat_id_)
end

if not database:get('bot:sens:spam:ban'..msg.chat_id_) then
spam_b = 250
else
spam_b = database:get('bot:sens:spam:ban'..msg.chat_id_)
end
	------------
  if database:get('bot:contact:mute'..msg.chat_id_) then
	lock_contact = '`lock | 🔐`'
	else
	lock_contact = '`unlock | 🔓`'
	end
	------------
  if database:get('bot:spam:mute'..msg.chat_id_) then
	mute_spam = '`lock | 🔐`'
	else
	mute_spam = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:english:mute'..msg.chat_id_) then
	lock_english = '`lock | 🔐`'
	else
	lock_english = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:arabic:mute'..msg.chat_id_) then
	lock_arabic = '`lock | 🔐`'
	else
	lock_arabic = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:forward:mute'..msg.chat_id_) then
	lock_forward = '`lock | 🔐`'
	else
	lock_forward = '`unlock | 🔓`'
	end
	------------
	if database:get("bot:welcome"..msg.chat_id_) then
	send_welcome = '`active | ✔`'
	else
	send_welcome = '`inactive | ⭕`'
end
		if not database:get('flood:max:warn'..msg.chat_id_) then
	flood_warn = 5
	else
	flood_warn = database:get('flood:max:warn'..msg.chat_id_)
end
	------------
	local ex = database:ttl("bot:charge:"..msg.chat_id_)
                if ex == -1 then
				exp_dat = '`NO Fanil`'
				else
				exp_dat = math.floor(ex / 86400) + 1
			    end
 	------------
	 local TXT = "*Group Settings Del*\n======================\n*Del all* : "..mute_all.."\n" .."*Del Links* : "..mute_links.."\n" .."*Del Edit* : "..mute_edit.."\n" .."*Del Bots* : "..mute_bots.."\n" .."*Del Flood* : "..mute_flood.."\n" .."*Del Inline* : "..mute_in.."\n" .."*Del English* : "..lock_english.."\n" .."*Del Forward* : "..lock_forward.."\n" .."*Del Pin* : "..lock_pin.."\n" .."*Del Arabic* : "..lock_arabic.."\n" .."*Del Hashtag* : "..lock_htag.."\n".."*Del tag* : "..lock_tag.."\n" .."*Del Webpage* : "..lock_wp.."\n" .."*Del Location* : "..lock_location.."\n" .."*Del Tgservice* : "..lock_tgservice.."\n"
.."*Del Spam* : "..mute_spam.."\n" .."*Del Photo* : "..mute_photo.."\n" .."*Del Text* : "..mute_text.."\n" .."*Del Gifs* : "..mute_gifs.."\n" .."*Del Voice* : "..mute_voice.."\n" .."*Del Music* : "..mute_music.."\n" .."*Del Video* : "..mute_video.."\n*Del Cmd* : "..lock_cmd.."\n"
.."======================\n*Welcome* : "..send_welcome.."\n*Flood Time*  "..flood_t.."\n" .."*Flood Max* : "..flood_m.."\n" .."*Flood Mute* : "..flood_warn.."\n" .."*Number Spam* : "..spam_c.."\n" .."*Warn Spam* : "..spam_d.."\n" .."*Ban Spam* : "..spam_b.."\n"
.."*Expire* : "..exp_dat.."\n"
         send(msg.chat_id_, msg.id_, 1, TXT, 1, 'md')
    end
    
  	 if text:match("^[#!/][Ss] [Ww][Aa][Rr][Nn]$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	if database:get('bot:muteallwarn'..msg.chat_id_) then
	mute_all = '`lock | 🔐`'
	else
	mute_all = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:text:warn'..msg.chat_id_) then
	mute_text = '`lock | 🔐`'
	else
	mute_text = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:photo:warn'..msg.chat_id_) then
	mute_photo = '`lock | 🔐`'
	else
	mute_photo = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:video:warn'..msg.chat_id_) then
	mute_video = '`lock | 🔐`'
	else
	mute_video = '`unlock | 🔓`'
end

	if database:get('bot:spam:warn'..msg.chat_id_) then
	mute_spam = '`lock | 🔐`'
	else
	mute_spam = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:gifs:warn'..msg.chat_id_) then
	mute_gifs = '`lock | 🔐`'
	else
	mute_gifs = '`unlock | 🔓`'
end

	if database:get('anti-flood:warn'..msg.chat_id_) then
	lock_flood = '`unlock | 🔓`'
	else 
	lock_flood = '`lock | 🔐`'
	end
	------------
	if database:get('bot:music:warn'..msg.chat_id_) then
	mute_music = '`lock | 🔐`'
	else
	mute_music = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:inline:warn'..msg.chat_id_) then
	mute_in = '`lock | 🔐`'
	else
	mute_in = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:voice:warn'..msg.chat_id_) then
	mute_voice = '`lock | 🔐`'
	else
	mute_voice = '`unlock | 🔓`'
	end
    ------------
	if database:get('bot:links:warn'..msg.chat_id_) then
	mute_links = '`lock | 🔐`'
	else
	mute_links = '`unlock | 🔓`'
	end
    ------------
	if database:get('bot:sticker:warn'..msg.chat_id_) then
	lock_sticker = '`lock | 🔐`'
	else
	lock_sticker = '`unlock | 🔓`'
	end
	------------
   if database:get('bot:cmd:warn'..msg.chat_id_) then
	lock_cmd = '`lock | 🔐`'
	else
	lock_cmd = '`unlock | 🔓`'
end

    if database:get('bot:webpage:warn'..msg.chat_id_) then
	lock_wp = '`lock | 🔐`'
	else
	lock_wp = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:hashtag:warn'..msg.chat_id_) then
	lock_htag = '`lock | 🔐`'
	else
	lock_htag = '`unlock | 🔓`'
end
	if database:get('bot:pin:warn'..msg.chat_id_) then
	lock_pin = '`lock | 🔐`'
	else
	lock_pin = '`unlock | 🔓`'
	end 
	------------
    if database:get('bot:tag:warn'..msg.chat_id_) then
	lock_tag = '`lock | 🔐`'
	else
	lock_tag = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:location:warn'..msg.chat_id_) then
	lock_location = '`lock | 🔐`'
	else
	lock_location = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:contact:warn'..msg.chat_id_) then
	lock_contact = '`lock | 🔐`'
	else
	lock_contact = '`unlock | 🔓`'
	end
	------------
	
    if database:get('bot:english:warn'..msg.chat_id_) then
	lock_english = '`lock | 🔐`'
	else
	lock_english = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:arabic:warn'..msg.chat_id_) then
	lock_arabic = '`lock | 🔐`'
	else
	lock_arabic = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:forward:warn'..msg.chat_id_) then
	lock_forward = '`lock | 🔐`'
	else
	lock_forward = '`unlock | 🔓`'
end
	------------
	------------
	local ex = database:ttl("bot:charge:"..msg.chat_id_)
                if ex == -1 then
				exp_dat = '`NO Fanil`'
				else
				exp_dat = math.floor(ex / 86400) + 1
			    end
 	------------
	 local TXT = "*Group Settings Warn*\n======================\n*Warn all* : "..mute_all.."\n" .."*Warn Links* : "..mute_links.."\n" .."*Warn Inline* : "..mute_in.."\n" .."*Warn Pin* : "..lock_pin.."\n" .."*Warn English* : "..lock_english.."\n" .."*Warn Forward* : "..lock_forward.."\n" .."*Warn Arabic* : "..lock_arabic.."\n" .."*Warn Hashtag* : "..lock_htag.."\n".."*Warn tag* : "..lock_tag.."\n" .."*Warn Webpag* : "..lock_wp.."\n" .."*Warn Location* : "..lock_location.."\n" .."*Warn flood* : "..lock_flood.."\n"
.."*Warn Spam* : "..mute_spam.."\n" .."*Warn Photo* : "..mute_photo.."\n" .."*Warn Text* : "..mute_text.."\n" .."*Warn Gifs* : "..mute_gifs.."\n" .."*Warn Voice* : "..mute_voice.."\n" .."*Warn Music* : "..mute_music.."\n" .."*Warn Video* : "..mute_video.."\n*Warn Cmd* : "..lock_cmd.."\n"
.."======================\n*Expire* : "..exp_dat.."\n"
         send(msg.chat_id_, msg.id_, 1, TXT, 1, 'md')
    end
    
  	 if text:match("^[#!/][Ss] [Bb][Aa][Nn]$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	if database:get('bot:muteallban'..msg.chat_id_) then
	mute_all = '`lock | 🔐`'
	else
	mute_all = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:text:ban'..msg.chat_id_) then
	mute_text = '`lock | 🔐`'
	else
	mute_text = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:photo:ban'..msg.chat_id_) then
	mute_photo = '`lock | 🔐`'
	else
	mute_photo = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:video:ban'..msg.chat_id_) then
	mute_video = '`lock | 🔐`'
	else
	mute_video = '`unlock | 🔓`'
end

	if database:get('bot:spam:ban'..msg.chat_id_) then
	mute_spam = '`lock | 🔐`'
	else
	mute_spam = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:gifs:ban'..msg.chat_id_) then
	mute_gifs = '`lock | 🔐`'
	else
	mute_gifs = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:music:ban'..msg.chat_id_) then
	mute_music = '`lock | 🔐`'
	else
	mute_music = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:inline:ban'..msg.chat_id_) then
	mute_in = '`lock | 🔐`'
	else
	mute_in = '`unlock | 🔓`'
	end
	------------
	if database:get('bot:voice:ban'..msg.chat_id_) then
	mute_voice = '`lock | 🔐`'
	else
	mute_voice = '`unlock | 🔓`'
	end
    ------------
	if database:get('bot:links:ban'..msg.chat_id_) then
	mute_links = '`lock | 🔐`'
	else
	mute_links = '`unlock | 🔓`'
	end
    ------------
	if database:get('bot:sticker:ban'..msg.chat_id_) then
	lock_sticker = '`lock | 🔐`'
	else
	lock_sticker = '`unlock | 🔓`'
	end
	------------
   if database:get('bot:cmd:ban'..msg.chat_id_) then
	lock_cmd = '`lock | 🔐`'
	else
	lock_cmd = '`unlock | 🔓`'
end

    if database:get('bot:webpage:ban'..msg.chat_id_) then
	lock_wp = '`lock | 🔐`'
	else
	lock_wp = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:hashtag:ban'..msg.chat_id_) then
	lock_htag = '`lock | 🔐`'
	else
	lock_htag = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:tag:ban'..msg.chat_id_) then
	lock_tag = '`lock | 🔐`'
	else
	lock_tag = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:location:ban'..msg.chat_id_) then
	lock_location = '`lock | 🔐`'
	else
	lock_location = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:contact:ban'..msg.chat_id_) then
	lock_contact = '`lock | 🔐`'
	else
	lock_contact = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:english:ban'..msg.chat_id_) then
	lock_english = '`lock | 🔐`'
	else
	lock_english = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:arabic:ban'..msg.chat_id_) then
	lock_arabic = '`lock | 🔐`'
	else
	lock_arabic = '`unlock | 🔓`'
	end
	------------
    if database:get('bot:forward:ban'..msg.chat_id_) then
	lock_forward = '`lock | 🔐`'
	else
	lock_forward = '`unlock | 🔓`'
	end
	------------
	------------
	local ex = database:ttl("bot:charge:"..msg.chat_id_)
                if ex == -1 then
				exp_dat = '`NO Fanil`'
				else
				exp_dat = math.floor(ex / 86400) + 1
			    end
 	------------
	 local TXT = "*Group Settings Ban*\n======================\n*Ban all* : "..mute_all.."\n" .."*Ban Links* : "..mute_links.."\n" .."*Ban Inline* : "..mute_in.."\n" .."*Ban English* : "..lock_english.."\n" .."*Ban Forward* : "..lock_forward.."\n" .."*Ban Arabic* : "..lock_arabic.."\n" .."*Ban Hashtag* : "..lock_htag.."\n".."*Ban tag* : "..lock_tag.."\n" .."*Ban Webpage* : "..lock_wp.."\n" .."*Ban Location* : "..lock_location.."\n"
.."*Ban Spam* : "..mute_spam.."\n" .."*Ban Photo* : "..mute_photo.."\n" .."*Ban Text* : "..mute_text.."\n" .."*Ban Gifs* : "..mute_gifs.."\n" .."*Ban Voice* : "..mute_voice.."\n" .."*Ban Music* : "..mute_music.."\n" .."*Ban Video* : "..mute_video.."\n*Ban Cmd* : "..lock_cmd.."\n"
.."======================\n*Expire* : "..exp_dat.."\n"
         send(msg.chat_id_, msg.id_, 1, TXT, 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]echo (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[#/!](echo) (.*)$")} 
         send(msg.chat_id_, msg.id_, 1, txt[2], 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/][Ss][Ee][Tt][Rr][Uu][Ll][Ee][Ss] (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[#/!]([Ss][Ee][Tt][Rr][Uu][Ll][Ee][Ss]) (.*)$")}
	database:set('bot:rules'..msg.chat_id_, txt[2])
         send(msg.chat_id_, msg.id_, 1, "*> Your ID :* _"..msg.sender_user_id_.."_\n*> UserName :* "..get_info(msg.sender_user_id_).."\n_> Group rules upadted..._", 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/][Rr][Uu][Ll][Ee][Ss]$") then
	local rules = database:get('bot:rules'..msg.chat_id_)
	if rules then
         send(msg.chat_id_, msg.id_, 1, '*Group Rules :-*\n'..rules, 1, 'md')
    else
         send(msg.chat_id_, msg.id_, 1, '*rules msg not saved!*', 1, 'md')
	end
	end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/][Dd][Ee][Vv]$") and msg.reply_to_message_id_ == 0 then
       sendContact(msg.chat_id_, msg.id_, 0, 1, nil, 9647707641864, '┋|| ♯םـــۄ୭دُʟ̤ɾ║☻➺❥ ||┋', '', bot_id)
    end
	-----------------------------------------------------------------------------------------------
		if text:match("^[/!#][Ss][Ee][Tt][Nn][Aa][Mm][Ee] (.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[/!#]([Ss][Ee][Tt][Nn][Aa][Mm][Ee]) (.*)$")}
	     changetitle(msg.chat_id_, txt[2])
         send(msg.chat_id_, msg.id_, 1, '_Group name updated!_', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Ee][Tt][Pp][Hh][Oo][Tt][Oo]$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_Please send a photo noew!_', 1, 'md')
		 database:set('bot:setphoto'..msg.chat_id_..':'..msg.sender_user_id_,true)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[/!#][Ss][Ee][Tt][Ee][Xx][Pp][Ii][Rr][Ee] (%d+)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
		local a = {string.match(text, "^[/!#]([Ee][Xx][Pp][Ii][Rr][Ee]) (%d+)$")} 
         send(msg.chat_id_, msg.id_, 1, '_Group Charged for_ *'..a[2]..'* _Days_', 1, 'md')
		 local time = a[2] * day
         database:setex("bot:charge:"..msg.chat_id_,time,true)
		 database:set("bot:enable:"..msg.chat_id_,true)
  end
  
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Tt][Aa][Tt][Ss]") and is_mod(msg.sender_user_id_, msg.chat_id_) then
    local ex = database:ttl("bot:charge:"..msg.chat_id_)
       if ex == -1 then
		send(msg.chat_id_, msg.id_, 1, '_No fanil_', 1, 'md')
       else
        local d = math.floor(ex / day ) + 1
	   		send(msg.chat_id_, msg.id_, 1, d.." *Group Days*", 1, 'md')
       end
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/][Ss][Tt][Aa][Tt][Ss] [Gg][Pp] (%d+)") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[#/!]([Ss][Tt][Aa][Tt][Ss] [Gg][Pp]) (%d+)$")} 
    local ex = database:ttl("bot:charge:"..txt[2])
       if ex == -1 then
		send(msg.chat_id_, msg.id_, 1, '_No fanil_', 1, 'md')
       else
        local d = math.floor(ex / day ) + 1
	   		send(msg.chat_id_, msg.id_, 1, d.." *Group is Days*", 1, 'md')
       end
    end
	-----------------------------------------------------------------------------------------------
	 if is_sudo(msg) then
  -----------------------------------------------------------------------------------------------
  if text:match("^[#!/][Ll][Ee][Aa][Vv][Ee] (-%d+)") and is_admin(msg.sender_user_id_, msg.chat_id_) then
  	local txt = {string.match(text, "^[#/!]([Ll][Ee][Aa][Vv][Ee]) (-%d+)$")} 
	   send(msg.chat_id_, msg.id_, 1, '*Group* '..txt[2]..' *remov', 1, 'md')
	   send(txt[2], 0, 1, '*Error\nGroup is not my', 1, 'html')
	   chat_leave(txt[2], bot_id)
  end
  -----------------------------------------------------------------------------------------------
  if text:match('^[#!/][Pp][Ll][Aa][Nn]1 (-%d+)') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[#/!]([Pp][Ll][Aa][Nn]1) (-%d+)$")} 
       local timeplan1 = 67369633
       database:setex("bot:charge:"..txt[2],timeplan1,true)
	   send(msg.chat_id_, msg.id_, 1, '_Group_ '..txt[2]..' *Done 30 Days Active*', 1, 'md')
	   send(txt[2], 0, 1, '*Done 30 Days Active*', 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, "*User "..msg.sender_user_id_.." Added bot to new group*" , 1, 'md')
       end
	   database:set("bot:enable:"..txt[2],true)
  end
  -----------------------------------------------------------------------------------------------
  if text:match('^[#!/][Pp][Ll][Aa][Nn]2(-%d+)') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[#/!]([Pp][Ll][Aa][Nn]2)(-%d+)$")} 
       local timeplan2 = 67369633
       database:setex("bot:charge:"..txt[2],timeplan2,true)
	   send(msg.chat_id_, msg.id_, 1, '_Group_ '..txt[2]..' *Done 90 Days Active*', 1, 'md')
	   send(txt[2], 0, 1, '*Done 90 Days Active*', 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, "*User "..msg.sender_user_id_.." Added bot to new group*" , 1, 'md')
       end
	   database:set("bot:enable:"..txt[2],true)
  end
  -----------------------------------------------------------------------------------------------
  if text:match('^[#!/][Pp][Ll][Aa][Nn]3(-%d+)') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[#/!]([Pp][Ll][Aa][Nn]3)(-%d+)$")} 
       database:set("bot:charge:"..txt[2],true)
	   send(msg.chat_id_, msg.id_, 1, '_Group_ '..txt[2]..' *Done Days No Fanil Active*', 1, 'md')
	   send(txt[2], 0, 1, '*Done Days No Fanil Active*', 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, "*User "..msg.sender_user_id_.." Added bot to new group*" , 1, 'md')
       end
	   database:set("bot:enable:"..txt[2],true)
  end
  -----------------------------------------------------------------------------------------------
  if text:match('^[/!#][Aa][Dd][Dd]$') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[/!#]([Aa][Dd][Dd])$")} 
    if database:get("bot:charge:"..msg.chat_id_) then
      send(msg.chat_id_, msg.id_, 1, '*Bot is already Added Group*', 1, 'md')
                  end
       if not database:get("bot:charge:"..msg.chat_id_) then
       database:set("bot:charge:"..msg.chat_id_,true)
	   send(msg.chat_id_, msg.id_, 1, "*> Your ID :* _"..msg.sender_user_id_.."_\n*> UserName :* "..get_info(msg.sender_user_id_).."\n*> Bot Added To Group*", 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, "*> Your ID :* _"..msg.sender_user_id_.."_\n*> UserName :* "..get_info(msg.sender_user_id_).."\n*> added bot to new group*" , 1, 'md')
       end
	   database:set("bot:enable:"..msg.chat_id_,true)
  end
  end
  -----------------------------------------------------------------------------------------------
  if text:match('^[/!#][Rr][Ee][Mm]$') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[/!#]([Rr][Ee][Mm])$")} 
      if not database:get("bot:charge:"..msg.chat_id_) then
      send(msg.chat_id_, msg.id_, 1, '*Bot is already remove Group*', 1, 'md')
                  end
      if database:get("bot:charge:"..msg.chat_id_) then
       database:del("bot:charge:"..msg.chat_id_)
	   send(msg.chat_id_, msg.id_, 1, "*> Your ID :* _"..msg.sender_user_id_.."_\n*> UserName :* "..get_info(msg.sender_user_id_).."\n*> Bot Removed To Group!*", 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, "*> Your ID :* _"..msg.sender_user_id_.."_\n*> UserName :* "..get_info(msg.sender_user_id_).."\n*> Removed bot from new group*" , 1, 'md')
       end
  end
  end
              
  -----------------------------------------------------------------------------------------------
   if text:match('^[#!/][Jj][Oo][Ii][Nn] (-%d+)') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[#!/]([Jj][Oo][Ii][Nn]) (-%d+)$")} 
	   send(msg.chat_id_, msg.id_, 1, '_Group_ '..txt[3]..' *is join*', 1, 'md')
	   send(txt[2], 0, 1, '*Sudo Joined To Grpup*', 1, 'md')
	   add_user(txt[2], msg.sender_user_id_, 10)
  end
   -----------------------------------------------------------------------------------------------
  end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]reload$") and is_sudo(msg) then
         send(msg.chat_id_, msg.id_, 1, '*Reloaded*', 1, 'md')
    end
    
     if text:match("^[#!/][Dd][Ee][Ll]") and msg.reply_to_message_id_ ~= 0 and is_mod(msg.sender_user_id_, msg.chat_id_) then
     delete_msg(msg.chat_id_, {[0] = msg.reply_to_message_id_})
     delete_msg(msg.chat_id_, {[0] = msg.id_})
            end
	----------------------------------------------------------------------------------------------
   if text:match('^[#!/][Dd]el (%d+)$') and is_sudo(msg) then
  local matches = {string.match(text, "^[#!/]([Dd]el) (%d+)$")}
   if msg.chat_id_:match("^-100") then
    if tonumber(matches[2]) > 100 or tonumber(matches[2]) < 1 then
      pm = '<b>> Error</b>\n<b>use /del [1-100] !<bb>'
    send(msg.chat_id_, msg.id_, 1, pm, 1, 'html')
                  else
      tdcli_function ({
     ID = "GetChatHistory",
       chat_id_ = msg.chat_id_,
          from_message_id_ = 0,
   offset_ = 0,
          limit_ = tonumber(matches[2])
    }, delmsg, nil)
      pm ='> <i>'..matches[2]..'</i> <b>Last Msgs Has Been Removed.</b>'
           send(msg.chat_id_, msg.id_, 1, pm, 1, 'html')
       end
        else pm ='> Not SuperGroup!'
      send(msg.chat_id_, msg.id_, 1, pm, 1, 'html')
                end
              end


		if text:match("^[#!/][Rr][Ee][Nn][Aa][Mm][Ee] (.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[#!/]([Rr][Ee][Nn][Aa][Mm][Ee]) (.*)$")}
	     changetitle(msg.chat_id_, txt[2])
         send(msg.chat_id_, msg.id_, 1, '_Group name updated!_', 1, 'md')
    end

    if text:match("^[#!/][Nn]ote (.*)$") and is_sudo(msg) then
    local txt = {string.match(text, "^[#!/]([Nn]ote) (.*)$")}
      database:set('owner:note1', txt[2])
      send(msg.chat_id_, msg.id_, 1, '*save!*', 1, 'md')
    end

    if text:match("^[#!/][Dd][Nn]ote$") and is_sudo(msg) then
      database:del('owner:note1',msg.chat_id_)
      send(msg.chat_id_, msg.id_, 1, '*Deleted!*', 1, 'md')
      end
  -----------------------------------------------------------------------------------------------
    if text:match("^[#!/][Gg]etnote$") and is_sudo(msg) then
    local note = database:get('owner:note1')
	if note then
         send(msg.chat_id_, msg.id_, 1, '*Note is :-*\n'..note, 1, 'md')
    else
         send(msg.chat_id_, msg.id_, 1, '*Note msg not saved!*', 1, 'md')
	end
	end
	-----------------------------------------------------------------------------------------------
	
if  text:match("^[#!/][Ii][Dd]$") and msg.reply_to_message_id_ == 0 then
local function getpro(extra, result, success)
local user_msgs = database:get('user:msgs'..msg.chat_id_..':'..msg.sender_user_id_)
   if result.photos_[0] then
            sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_,"> Group ID : "..msg.chat_id_:gsub('-100','').."\n> Your ID : "..msg.sender_user_id_.."\n> UserName : "..get_info(msg.sender_user_id_).."\n> Msgs : "..user_msgs,msg.id_,msg.id_.."")
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt Profile Photo!!\n\n> *> Group ID :* "..msg.chat_id_:gsub('-100','').."\n*> Your ID :* "..msg.sender_user_id_.."\n*> UserName :* "..get_info(msg.sender_user_id_).."\n*> Msgs : *_"..user_msgs.."_", 1, 'md')
   end
   end
   tdcli_function ({
    ID = "GetUserProfilePhotos",
    user_id_ = msg.sender_user_id_,
    offset_ = 0,
    limit_ = 1
  }, getpro, nil)
end

if text:match("^[#!/][Mm][Ee]$") and msg.reply_to_message_id_ == 0 then
local user_msgs = database:get('user:msgs'..msg.chat_id_..':'..msg.sender_user_id_)
          function get_me(extra,result,success)
      if is_sudo(msg) then
      t = 'Sudo'
      elseif is_admin(msg.sender_user_id_) then
      t = 'Global Admin'
      elseif is_owner(msg.sender_user_id_, msg.chat_id_) then
      t = 'Group Owner'
      elseif is_mod(msg.sender_user_id_, msg.chat_id_) then
      t = 'Group Moderator'
      else
      t = 'Group Member'
    end
    if result.username_ then
    result.username_ = '@'..result.username_
      else
    result.username_ = '`Not Found`'
        end
    if result.last_name_ then
    lastname = result.last_name_
       else
    lastname = '`Not Found`'
       end
      send(msg.chat_id_, msg.id_, 1, "*> Group ID :* `"..msg.chat_id_:gsub('-100','').."`\n*> Your ID :* `"..msg.sender_user_id_.."`\n*> Your Name :* "..result.first_name_.."\n*> UserName :* "..result.username_.."\n*> Your Rank :* `"..t.."`\n*> Msgs : *`"..user_msgs.."`", 1, 'md')
    end
          getUser(msg.sender_user_id_,get_me)
    end
 
   if text:match('^[#!/][Ww][Hh][Oo][Ii][Ss] (%d+)') then
        local id = text:match('^[#!/][Ww][Hh][Oo][Ii][Ss] (%d+)')
        local text = 'Click to view user!'
      tdcli_function ({ID="SendMessage", chat_id_=msg.chat_id_, reply_to_message_id_=msg.id_, disable_notification_=0, from_background_=1, reply_markup_=nil, input_message_content_={ID="InputMessageText", text_=text, disable_web_page_preview_=1, clear_draft_=0, entities_={[0] = {ID="MessageEntityMentionName", offset_=0, length_=19, user_id_=id}}}}, dl_cb, nil)
   end
   -----------------------------------------------------------------------------------------------
   if text:match("^[#!/][Pp][Ii][Nn]$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
       pin(msg.chat_id_,msg.reply_to_message_id_,0)
	   database:set('pinnedmsg'..msg.chat_id_,msg.reply_to_message_id_)
	            send(msg.chat_id_, msg.id_, 1, '_Msg han been_ *pinned!*', 1, 'md')
   end
   -----------------------------------------------------------------------------------------------
   if text:match("^[#!/][Uu][Nn][Pp][Ii][Nn]$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
         unpinmsg(msg.chat_id_)
         send(msg.chat_id_, msg.id_, 1, '_Pinned Msg han been_ *unpinned!*', 1, 'md')
   end
   -----------------------------------------------------------------------------------------------
   if text:match("^[#!/]repin$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
local pin_id = database:get('pinnedmsg'..msg.chat_id_)
        if pin_id then
         pin(msg.chat_id_,pin_id,0)
         send(msg.chat_id_, msg.id_, 1, '*Last Pinned msg has been repinned!*', 1, 'md')
		else
         send(msg.chat_id_, msg.id_, 1, "*i Can't find last pinned msgs...*", 1, 'md')
		 end
   end
   -----------------------------------------------------------------------------------------------
   if text:match("^[#!/][Hh][Ee][Ll][Pp]") and is_mod(msg.sender_user_id_, msg.chat_id_) then
   
   local text =  [[
`هناك`  *6* `اوامر لعرضها`
*======================*
*h1* `لعرض اوامر الحمايه`
*======================*
*h2* `لعرض اوامر الحمايه بالتحذير`
*======================*
*h3* `لعرض اوامر الحمايه بالطرد`
*======================*
*h4* `لعرض اوامر الادمنيه`
*======================*
*h5* `لعرض اوامر المجموعه`
*======================*
*h6* `لعرض اوامر المطورين`
*======================*
]]
                send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
   end
   
   if text:match("^[#!/][Hh]1") and is_mod(msg.sender_user_id_, msg.chat_id_) then
   
   local text =  [[
*lock* `للقفل`
*unlock* `للفتح`
*======================*
*| links |* `الروابط`
*| tag |* `المعرف`
*| hashtag |* `التاك`
*| cmd |* `السلاش`
*| edit |* `التعديل`
*| webpage |* `الروابط الخارجيه`
*======================*
*| flood ban |* `التكرار بالطرد`
*| flood mute |* `التكرار بالكتم`
*| gif |* `الصور المتحركه`
*| photo |* `الصور`
*| sticker |* `الملصقات`
*| video |* `الفيديو`
*| inline |* `لستات شفافه`
*======================*
*| text |* `الدردشه`
*| fwd |* `التوجيه`
*| music |* `الاغاني`
*| voice |* `الصوت`
*| contact |* `جهات الاتصال`
*| service |* `اشعارات الدخول`
*======================*
*| location |* `المواقع`
*| bots |* `البوتات`
*| spam |* `الكلايش`
*| arabic |* `العربيه`
*| english |* `الانكليزيه`
*| all |* `كل الميديا`
*| all |* `مع العدد قفل الميديا بالثواني`
*======================*
]]
                send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
   end
   
   if text:match("^[#!/][Hh]2") and is_mod(msg.sender_user_id_, msg.chat_id_) then
   
   local text =  [[
*lock* `للقفل`
*unlock* `للفتح`
*======================*
*| links warn |* `الروابط`
*| tag warn |* `المعرف`
*| hashtag warn |* `التاك`
*| cmd warn |* `السلاش`
*| webpage warn |* `الروابط الخارجيه`
*======================*
*| gif warn |* `الصور المتحركه`
*| photo warn |* `الصور`
*| sticker warn |* `الملصقات`
*| video warn |* `الفيديو`
*| inline warn |* `لستات شفافه`
*======================*
*| text warn |* `الدردشه`
*| fwd warn |* `التوجيه`
*| music warn |* `الاغاني`
*| voice warn |* `الصوت`
*| contact warn |* `جهات الاتصال`
*======================*
*| location warn |* `المواقع`
*| spam |* `الكلايش`
*| arabic warn |* `العربيه`
*| english warn |* `الانكليزيه`
*| all warn |* `كل الميديا`
*======================*
]]
                send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
   end
   
   if text:match("^[#!/][Hh]3") and is_mod(msg.sender_user_id_, msg.chat_id_) then
   
   local text =  [[
*lock* `للقفل`
*unlock* `للفتح`
*======================*
*| links ban |* `الروابط`
*| tag ban |* `المعرف`
*| hashtag ban |* `التاك`
*| cmd ban |* `السلاش`
*| webpage ban |* `الروابط الخارجيه`
*======================*
*| gif ban |* `الصور المتحركه`
*| photo ban |* `الصور`
*| sticker ban |* `الملصقات`
*| video ban |* `الفيديو`
*| inline ban |* `لستات شفافه`
*======================*
*| text ban |* `الدردشه`
*| fwd ban |* `التوجيه`
*| music ban |* `الاغاني`
*| voice ban |* `الصوت`
*| contact ban |* `جهات الاتصال`
*| location ban |* `المواقع`
*======================*
*| spam ban |* `الكلايش`
*| arabic ban |* `العربيه`
*| english ban |* `الانكليزيه`
*| all ban |* `كل الميديا`
*======================*
]]
                send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
   end
   
   if text:match("^[#!/][Hh]4") and is_mod(msg.sender_user_id_, msg.chat_id_) then
   
   local text =  [[
*======================*
*| setmote |* `رفع ادمن` 
*| remmote |* `ازاله ادمن` 
*| unsilent |* `لالغاء كتم العضو` 
*| silent |* `لكتم عضو` 
*| ban |* `حظر عضو` 
*| unban |* `الغاء حظر العضو` 
*| id |* `لاظهار الايدي [بالرد] `
*| pin |* `تثبيت رساله!`
*| unpin |* `الغاء تثبيت الرساله!`
*======================*
*| s del |* `اظهار اعدادات المسح`
*| s warn |* `اظهار اعدادات التحذير`
*| s ban |* `اظهار اعدادات الطرد`
*| silentlist |* `اظهار المكتومين`
*| banlist |* `اظهار المحظورين`
*| modlist |* `اظهار الادمنيه`
*| del |* `حذف رساله بالرد`
*| link |* `اظهار الرابط`
*| rules |* `اظهار القوانين`
*======================*
*| bad |* `منع كلمه` 
*| unbad |* `الغاء منع كلمه` 
*| badlist |* `اظهار الكلمات الممنوعه` 
*| stats |* `لمعرفه ايام البوت`
*| del wlc |* `حذف الترحيب` 
*| set wlc |* `وضع الترحيب` 
*| wlc on |* `تفعيل الترحيب` 
*| wlc off |* `تعطيل الترحيب` 
*| get wlc |* `معرفه الترحيب الحالي` 
*======================*
]]
                send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
   end

   if text:match("^[#!/][Hh]5") and is_mod(msg.sender_user_id_, msg.chat_id_) then
   
   local text =  [[
*======================*
*clean* `مع الاوامر ادناه بوضع فراغ`

*| banlist |* `المحظورين`
*| badlist |* `كلمات المحظوره`
*| modlist |* `الادمنيه`
*| link |* `الرابط المحفوظ`
*| silentlist |* `المكتومين`
*| bots |* `بوتات تفليش وغيرها`
*| rules |* `القوانين`
*======================*
*set* `مع الاوامر ادناه بدون فراغ`

*| link |* `لوضع رابط`
*| rules |* `لوضع قوانين`
*| name |* `مع الاسم لوضع اسم`
*| photo |* `لوضع صوره`

*======================*

*| flood ban |* `وضع تكرار بالطرد`
*| flood mute |* `وضع تكرار بالكتم`
*| flood time |* `لوضع زمن تكرار بالطرد او الكتم`
*| spam del |* `وضع عدد السبام بالمسح`
*| spam warn |* `وضع عدد السبام بالتحذير`
*| spam ban |* `وضع عدد السبام بالطرد`
*======================*
]]
                send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
   end
   
   if text:match("^[#!/][Hh]6") and is_sudo(msg) then
   
   local text =  [[
*======================*
*| add |* `تفعيل البوت`
*| rem |* `تعطيل البوت`
*| setexpire |* `وضع ايام للبوت`
*| stats gp |* `لمعرفه ايام البوت`
*| plan1 + id |* `تفعيل البوت 30 يوم`
*| plan2 + id |* `تفعيل البوت 90 يوم`
*| plan3 + id |* `تفعيل البوت لا نهائي`
*| join + id |* `لاضافتك للكروب`
*| leave + id |* `لخروج البوت`
*| leave |* `لخروج البوت`
*| stats gp + id |* `لمعرفه  ايام البوت`
*| view |* `لاظهار مشاهدات منشور`
*| note |* `لحفظ كليشه`
*| dnote |* `لحذف الكليشه`
*| getnote |* `لاظهار الكليشه`
*| reload |* `لتنشيط البوت`
*| clean gbanlist |* `لحذف الحظر العام`
*| clean owners |* `لحذف قائمه المدراء`
*| adminlist |* `لاظهار ادمنيه البوت`
*| gbanlist |* `لاظهار المحظورين عام `
*| ownerlist |* `لاظهار مدراء البوت`
*| setadmin |* `لاضافه ادمن`
*| remadmin |* `لحذف ادمن`
*| setowner |* `لاضافه مدير`
*| remowner |* `لحذف مدير`
*| banall |* `لحظر العام`
*| unbanall |* `لالغاء العام`
*| groups |* `عدد كروبات البوت`
*| bc |* `لنشر شئ`
*| show edit |* `لكشف التعديل`
*| del |* `ويه العدد حذف رسائل`
*======================*
]]
                send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
   end
   -----------------------------------------------------------------------------------------------
   if text:match("^[#!/][Vv][Ii][Ee][Ww]$") then
        database:set('bot:viewget'..msg.sender_user_id_,true)
        send(msg.chat_id_, msg.id_, 1, '*Please send a post now!*', 1, 'md')
   end
  end
  -----------------------------------------------------------------------------------------------
 end
  -----------------------------------------------------------------------------------------------
                                       -- end code --
  -----------------------------------------------------------------------------------------------
  elseif (data.ID == "UpdateChat") then
    chat = data.chat_
    chats[chat.id_] = chat
  -----------------------------------------------------------------------------------------------
  elseif (data.ID == "UpdateMessageEdited") then
   local msg = data
  -- vardump(msg)
  	function get_msg_contact(extra, result, success)
	local text = (result.content_.text_ or result.content_.caption_)
    --vardump(result)
	if result.id_ and result.content_.text_ then
	database:set('bot:editid'..result.id_,result.content_.text_)
	end
  if not is_mod(result.sender_user_id_, result.chat_id_) then
   check_filter_words(result, text)
   if text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or
text:match("[Tt].[Mm][Ee]") or text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end

   if text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or
text:match("[Tt].[Mm][Ee]") or text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:warn'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
       send(msg.chat_id_, 0, 1, "<code>Don't edit links in Group</code>\n<b>The Block</b>\n", 1, 'html')
	end
end
end

   	if text:match("[Hh][Tt][Tt][Pp][Ss]://") or text:match("[Hh][Tt][Tt][Pp]://") or text:match(".[Ii][Rr]") or text:match(".[Cc][Oo][Mm]") or text:match(".[Oo][Rr][Gg]") or text:match(".[Ii][Nn][Ff][Oo]") or text:match("[Ww][Ww][Ww].") or text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
	
   if database:get('bot:webpage:warn'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
       send(msg.chat_id_, 0, 1, "<code>Don't edit webpage in Group</code>\n", 1, 'html')
	end
end
end
   if text:match("@") then
   if database:get('bot:tag:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
	   if database:get('bot:tag:warn'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
       send(msg.chat_id_, 0, 1, "<code>Don't edit tag in Group</code>\n", 1, 'html')
	end
   	if text:match("#") then
   if database:get('bot:hashtag:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
	   if database:get('bot:hashtag:warn'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
       send(msg.chat_id_, 0, 1, "<code>Don't edit hashtag in Group</code>\n", 1, 'html')
	end
   	if text:match("/") then
   if database:get('bot:cmd:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
	   if database:get('bot:cmd:warn'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
       send(msg.chat_id_, 0, 1, "<code>Don't edit cmd in Group</code>\n", 1, 'html')
	end
end
   	if text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
	end
	   if database:get('bot:arabic:warn'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
              send(msg.chat_id_, 0, 1, "<code>Don't edit arabic in Group</code>\n", 1, 'html')
	end
   end
   if text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
	   if database:get('bot:english:warn'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
              send(msg.chat_id_, 0, 1, "<code>Don't edit english in Group</code>\n", 1, 'html')
end
end
    end
	end
	if database:get('editmsg'..msg.chat_id_) == 'delmsg' then
        local id = msg.message_id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
              delete_msg(chat,msgs)
                            send(msg.chat_id_, 0, 1, "<code>Don't edit in Group</code>\n", 1, 'html')
	elseif database:get('editmsg'..msg.chat_id_) == 'didam' then
	if database:get('bot:editid'..msg.message_id_) then
		local old_text = database:get('bot:editid'..msg.message_id_)
     send(msg.chat_id_, msg.message_id_, 1, '*You edit msg 😂\nYour letter Previous :*\n*[ '..old_text..' ]*', 1, 'md')
	end
end

    getMessage(msg.chat_id_, msg.message_id_,get_msg_contact)
  -----------------------------------------------------------------------------------------------
  elseif (data.ID == "UpdateOption" and data.name_ == "my_id") then
    tdcli_function ({ID="GetChats", offset_order_="9223372036854775807", offset_chat_id_=0, limit_=20}, dl_cb, nil)    
  end
  -----------------------------------------------------------------------------------------------
end

--[[ 
   _____    _        _    _    _____    Dev @EMADOFFICAL
  |_   _|__| |__    / \  | | _| ____|   Dev @lIMyIl 
    | |/ __| '_ \  / _ \ | |/ /  _|     Dev @IX00XI
    | |\__ \ | | |/ ___ \|   <| |___    Dev @H_173
    |_||___/_| |_/_/   \_\_|\_\_____|   Dev @lIESIl
              CH > @lTSHAKEl_CH
--]]
