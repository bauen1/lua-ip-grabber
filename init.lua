-- Dependencys (all luasocket)
local socket = require "socket"
local dns = socket.dns
--local http = require "socke.thttp"
local ltn12 = require "ltn12"

function generateURL (url)
  -- TODO: Implement
  return url
end

function launchServer (port)
  local server = socket.bind ("*", port or 8080)
  server:settimeout (0.1)

  while true do
    local client, err = server:accept ()

    if err then
      if err == "timeout" then
        socket.sleep (0.1)
      else
        print (err)
        return;
      end
    else
      local line, err = client:receive ()

      if line then
        local peername = client:getpeername ()
        print ("'" .. line .. "' from '" .. peername .. "' / '" .. (dns.tohostname (peername) or "nil") .. "'")

        -- Get target location:
        local method, url, ver = line:match ("^([^%s]*) (.*) HTTP/(%d.%d)$")

        local target = ""

        if url:sub (1,9) == "/?target=" then
          target = url:sub (10, -1);
        else
        end

        client:send ("HTTP/1.1 302\r\nlocation: " .. target .. "\r\n")
        --client:send ("HTTP/1.1 200\r\ncontent-length: 5\r\ncontent-type: text/plain\r\ncontent-encoding: UTF-8\r\n\r\nhello")
      end

      client:close ()
    end
  end

  return ""
end

local args = table.pack (...)

if args.n >= 1 then
  if tonumber (args[1], 10) then
    -- Launch the server
    local port = tonumber (args[1], 10)
    if (port < 1) or (port > 65535) then
      io.write ("the port must be between 1 and 65535")
      return 0;
    end

    return launchServer (port)
  else
    -- Generate url
    print (generateURL (args[1]))
  end
else
  -- Print manual
  io.write ([[
Usage: lua init.lua <port/url>
port: a valid number between 1 and 65535, will launch the server
url: a http url, will generate a url that on visit will print the visitors ip & hostname
]])
end
