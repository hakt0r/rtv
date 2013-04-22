###
  Liquidsoap module - part of the RTV project
  c) 2012 - 2013
    Sebastian Glaser <anx@ulzq.de>
  Licensed under GNU GPLv3
###

LiquidBridge = require "./bridge"

module.exports =
  libs : [ 'child_process', 'net' ]
  init : (config) ->
    { PREFIX } = this
    { child_process, net, json, message } = @api
    J = json # functional json creator

    @api.Liq = Liq = new LiquidBridge
      server : config.server
      port : config.port
      smin : 2
      smax : 5

      play : (uri, callback) =>
        Liq.execute "player.push #{uri}", (data) =>
          callback("AQ: #{uri} @ #{data.trim()}")

      mass_meta : (queue,callback) =>
        # TODO: LiquidBridge suports mass request now ;)
        # NOTE: BUT it seemed slow when i wrote it
        # NOTE: SO  maybe use this code afterall
        meta = {}; jcount = 0
        join = => (callback(meta) if ++jcount >= queue.length)
        branch = (rid) =>
          Liq.execute "request.metadata #{rid}",(data) =>
            meta[jcount] = Liq.parse_meta(data); join()
        branch rid for rid in queue

      parse_mixer : (data) =>
        a = {}
        for k in data.split(" ")
          if (p = k.indexOf("=")) isnt -1
            a[k.substr(0,p)] = k.substr(p+1,k.length-p-1)
        return a

      parse_meta : (data) =>
        a = {}
        for k in data.split("\n")
          if (p = k.indexOf("=")) isnt -1
            a[k.substr(0,p)] = k.substr(p+2,k.length-p-3)
        return a

      parse_meta_to_title : (m) =>
        a = Liq.parse_meta(m)
        artist   = a["artist"]
        title    = a["title"]
        source   = a["source"]
        filename = a["filename"]
        source   = "UPS"  if ! source?
        filename = "OOPS" if ! filename?
        if ! title?
          title = filename
          title = title.replace(/^.*\//,"")
          title = title.replace(/.[^.]+$/,"")
          title = title.replace("_","")
        title = "#{artist} - #{title}" if artist?
        return "#{title} (#{source})"

      command : (request,args)=>
        switch args[0]
          when "go"
            Liq.execute "go #{args[1]}", (data) =>
              message {studio:{go:args[1],result:data}}
          when "search"
            return child_process.exec "find #{PREFIX}|grep '#{args[1]}'",
              (err,stdout,stderr) =>
                request.reply stdout.trim()
          when "fade"
            action = args[1]
            duration = if args[2]? then args[2] else 1000
            steps = 100; steplength = duration / steps
            snum = 0; shd = null
            switch action
              when "set"
                to = parseInt(args[2])
                right = to
                left = 100 - right
                Liq.execute "xfade.volume 0 #{left}\nxfade.volume 1 #{right}", =>
                  message {studio:{xfade:{set:to}}}
              when "left", "right"
                [s1,s2] = if action == "right" then [1,0] else [0,1]
                step = () =>
                  Liq.execute "xfade.volume #{s1} #{snum}\nxfade.volume #{s2} #{100-snum}", =>
                    message {studio:{xfade:{to:action}}}
                  if snum++ >= steps
                    clearInterval shd
                shd = setInterval(step, steplength)
              else request.reply "usage:\n" + 
                "  left|right [duration in ms] [steps]\n" +
                "  to <0-100> 0 := left 100 := right"
          when "master", "monitor"
            [ deck, action, id, value ] = args
            switch action
              when "select", "single", "volume"
                Liq.execute "#{deck}.#{action} #{id} #{value}", (value) =>
                  value = Liq.parse_mixer(value)
                  value.id = id
                  message J("studio",J(deck,J("state",value)))
              when "volume.out"
                Liq.execute "#{deck}.#{action} #{id}", (value) =>
                  message J("studio",J(deck,J("state",value)))
              when "refresh"
                Liq.execute [
                  "#{deck}.volume.out", 
                  "#{deck}.status 0", "#{deck}.status 1",
                  "#{deck}.status 2", "#{deck}.status 3" ],
                  (data) =>
                    state = {output:data.shift(),input:{}}
                    state.input[i] = Liq.parse_mixer(d) for i,d of data
                    message J("studio",J(deck,J(action,state)))
          when "left", "right"
            [ deck, action, value ] = args
            switch action
              when "play", "pause", "stop", "status", "skip"
                Liq.execute "#{deck}.#{action}",(data) =>
                  message J("studio",J(deck,J(action,data)))
              when "volume", "remove"
                Liq.execute "#{deck}.#{action} #{value}",(data) =>
                  message J("studio",J(deck,J(action,value,"result",data)))
              when "move"
                Liq.execute "#{deck}.#{action} #{value} #{args[3]}", (data) =>
                  message J("studio",J(deck,J(action,J("rid",value,"to",args[3]))))
              when "push", "insert"
                cmd = "#{deck}.#{action} #{value}"
                cmd += " " + args[3] if args[3]?
                Liq.execute cmd, (data) =>
                  rid = parseInt(data.trim())
                  unless rid > -1
                    Liq.execute "request.trace #{rid}",(data) =>
                      request.reply data
                  Liq.execute "request.metadata #{rid}",(data) =>
                    data = Liq.parse_meta(data)
                    message J("studio",J(deck,J(action,J("rid",rid,"meta",data))))
              when "refresh" 
                Liq.execute "#{deck}.queue",(data) =>
                  queue = data.split(' ').map (i)-> parseInt(i)
                  Liq.mass_meta queue,(data) =>
                    # console.log data
                    message J("studio",J(deck,J("refresh",data)))
              else request.reply "usage:volume push insert remove play pause stop status"
          else request.reply "usage: search go left right master monitor"

    Liq.evt_rcv = net.createServer (socket) =>
      socket.buffer = ""
      socket.on 'data', (data) =>
        socket.buffer += data.toString("utf8")
        try
          data = JSON.parse(data)
          message data
          socket.destroy()
        catch e
          console.log "EVT_RCV::error", e

    Liq.evt_rcv.listen config.rcvport, '127.0.0.1'

    # TODO: make sure this is workthrough
    ## Liq.execute "master.select 0 true", console.log

    # TODO: nampespace commands into !rtv (acls?)
    @new_command
      cmd   : '!restart'
      admin : true
      args  : true
      fnc   : (request, args) =>
        switch args[1]
          when "help" then request.reply "(radio|bot)"
          when "radio"
            child_process.exec "pkill liquidsoap;liquidsoap -d #{PREFIX}/liq/radio.liq",
              (err,stdout,stderr) =>
                stdout = stdout.trim()
                request.reply  "Error (on radio restart): #{stderr}" if err
                request.reply "Message (on radio restart): #{stdout}" if stdout != ""
          when "bot"
            kill = "kill $(ps x|grep bot|grep coffee|awk '{print $1}')"
            request.reply "TODO: #{kill}"

    @new_command
      cmd : '!song'
      fnc : (request) =>
        Liq.execute "radio-aac.metadata", (data) =>
          data = data.split("\n---").pop().split("\n")
          data.shift(); data = data.join("\n")
          request.reply Liq.parse_meta_to_title(data)

    @new_command
      cmd :'!log',
      fnc : (request) =>
        Liq.execute "radio-aac.metadata", (data) =>
          q = []; x = data.split("\n--- "); x.shift()
          for index, i of x
            qid = i.substr(0,5)
            qid = qid.replace(/\ .*/, "")
            q.push Liq.parse_meta_to_title(i)
          data = "Radio Log:\n" + q.join("\n")
          request.reply data

    @new_command
      cmd : '!live',
      fnc : (request) =>
        Liq.execute "live.status", (data) -> request.reply data

    @new_command
      cmd   : '!raw'
      admin : true
      fnc   : (request, message) =>
        message = message.split(" ")
        message.shift()
        message = message.join(" ")
        Liq.execute message, (data)-> request.reply data

    @new_command
      cmd   : '!kick'
      admin : true
      fnc   : (request) =>
        Liq.execute "live.kick", (data)-> request.reply data

    @new_command
      cmd   : '!play'
      args  : true
      admin : true
      fnc   : (request, args) =>
        file = args[0].trim()
        file = "#{PREFIX}/#{file}" unless file[0]=="/" or file.match(/[a-zA-Z]+:\/\//)
        Liq.play file, (result)-> request.reply result

    @new_command
      cmd   : '!s'
      args  : true
      admin : true
      fnc   : Liq.command