###
  Liquid Bridge - part of the RTV project
  c) 2012 - 2013
    Sebastian Glaser <anx@ulzq.de>
  Licensed under GNU GPLv3

  TODO: handle connection timeout from liquidsop
###

module.exports = 
  create : (opts={}) ->
    { conservative, sockets, host, port } = opts
    host         = "127.0.0.1" unless host?
    port         = 1234        unless port?
    conservative = true        unless conservative?
    sockets      = 5           unless sockets?
    net          = require 'net'
    que          = []          # a nice short way to say queue
    return (cmds,callback) ->
      cmds = [cmds] if typeof cmds is "string"
      return que.push [cmds,callback] if sockets is 0; sockets-- # overflow handling
      net.connect(port,host,->
        @setEncoding('utf8')
        @done = 0; @buffer = ""; @count = cmds.length
        @on('data', (data) ->
          return if data is "Bye!\r\n"
          data = data.replace(/\r\n/g,"\n")
          @buffer += data
          @done   += m.length if ( m = data.match /\nEND\n/g ) isnt null
          if @done is @count
            data = @buffer.trim().substring(-4).split("\nEND\n")
            callback if @count is 1 then data.toString() else data
            if que.length > 0
              unless conservative
                @end "exit\n"; sockets++
                execute.apply null, que.shift()
              else
                [ cmds, callback ] = que.shift()
                @done = 0; @buffer = ""; @count = cmds.length
                @write cmds.join('\n')+"\n"
            else
              @end "exit\n"
              sockets++
        @write cmds.join('\n')+"\n" )
      ).on('error',console.error)