#!/usr/bin/env lua
--[[

The MIT License (MIT)

Copyright (c) 2016-2017 bauen1

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]--
-- Dependencies: luasocket
local socket = require "socket"
local dns = socket.dns
local ltn12 = require "ltn12"

function printf(...)
  return print(string.format(...))
end

function handle_client(c)
  c:settimeout(0.5)
  local peername = c:getpeername()
  printf("Connection from '%s' / '%s'", peername, (dns.tohostname (peername) or "nil"))
  local l, e = c:receive()
  c:send("HTTP/1.0 ")
  if l then
    -- Get target location:
    local method, url, ver = l:match("^([^%s]*) (.*) HTTP/(%d.%d)$") -- Get target redirection url

    local target = ""

    if url then
      if url:sub(1,9) == "/?target=" then
        target = url:sub (10, -1);
      else
        target = "https://google.com/"
      end

      c:send("302\r\nlocation: " .. target .. "\r\n") -- Redirect
    else
      c:send("200 OK\r\n\r\nHello there Stranger ...") -- Show a basic page
    end
  end
  c:close()
end

function launchServer (address, port)
  local server = assert(socket.bind(address, port))
  printf("Listening on %s:%s", address, port)
  -- Normally this should open a listening socket (server) on every ipv6 address available on 'port'

  server:settimeout(5) -- So we can Ctrl+C and still cleanup the socket

  while true do
    local client, err = server:accept() -- Accept a new client

    if err then
      if err == "timeout" then
        socket.sleep(0.1)
      else
        print(err)
        return;
      end
    else
      local success, err = pcall(handle_client, client)
      if not success then
        printf("error in 'handle_client': %s", err)
      end
    end
  end
end

local port = tonumber(arg[2])
if port and (port >= 0) and (port <= 65535) then
  launchServer(arg[1], port)
else
  printf([[
Usage: %s <ip_addr> <port>
  ip_addr: '::' to bind to all ipv6 (and ipv4) addresses
           '*' to bind to all ipv4 addresses
  port:    0-65535
]], arg[0])
  return
end
