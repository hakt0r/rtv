###
  BEASTY WEBINTERFACE
    fame goes to express, ws, and webrtc
    tiamat was written for this
###

class RTCClient
  constructor : (opts={}) ->
    { @display, @url, @child_process } = opts
    @child_process = require "child_process" unless @child_process?
    @display = 50                            unless @display?
    @url = "http://localhost:8022"           unless @url?
  start : ->
    @screen = @child_process.spawn "xvfb-run",
      [ "--server-args='-screen #{@display}, 1024x768x16'",
        "chromium",
        "-start-maximized",
        @url ]
    @vnc = @child_process.spawn "Xvnc", ["-display",":#{@display}","-loop"]
  stop : ->
    @vnc.kill(9)
    @screen.kill(9)

module.exports =
  deps : [ 'web', 'database' ]
  libs : [
    'express', 'ws', 'fs', 'tiamat', 'child_process'
    { WebRTC : 'webrtc.io', coffee : 'coffee-script' } ]
  init : (config) ->
    { PREFIX } = this
    { Liq, Web, ws, child_process, tiamat, express, WebRTC } = @api
    WebSocketServer = ws.Server
    Bot = this
    
    ## static web server
    webroot = "#{PREFIX}/bot/mod/web/root"
    Web.static = app = express()
    app.use express.compress()
    app.use "/", express.static(webroot)

    ## tiamat app compiler
    @compile_page = tiamat
    @compile_page # into one file
      compress  : on
      hashes    : no
      verbose   : yes
      recompile : no # TODO: yes
      webroot   : webroot
      template  : "template.html"
      dest      : "#{webroot}/index.html"
    # ^^ tiamat allows dest outside webroot

    # Start client and server
    config.rtc = 8022 unless config.rtc?
    Web.rtc = WebRTC.listen config.rtc
    Web.rtcclient = new RTCClient
      child_process : child_process
      display : 50
      url : "http://localhost:#{config.static}/template.html#rtc-client"

    @new_command
      cmd   : "!rtc"
      admin : true
      args  : true
      fnc   : (request, args) =>
        switch args.shift()
          when "on" then Web.rtcclient.start()
          when "off" then Web.rtcclient.stop()
          else request.reply "hmm?"

    ## websocket server
    Web.sock = new WebSocketServer({port:config.websock})
    Web.sock.conns = []
    Web.sock.group = {studio:[],meta:[],news:[]}

    Web.sock.gone = (ws)->
      delete @conns[@conns.indexOf(ws)]
      # TODO: check groups/acls -> core 

    Web.sock.chancast = (msg)->
      for dest, m of msg
        continue unless Web.sock.group[dest]
        grp = Web.sock.group[dest]
        m = "{\"#{dest}\":#{JSON.stringify(m)}}"
        # console.log "chancast(#{dest}) #{m}"
        for key, ws of grp
          try ws.send m
          catch e
            Web.sock.gone ws

    Web.sock.on "connection", (ws) ->
      ws.login = false
      Web.sock.conns.push ws
      Web.sock.group['news'].push ws
      Web.sock.group['meta'].push ws
      ws.message = (m)-> @send JSON.stringify(m)
      ws.on "message", (m)-> 
        try
          m = JSON.parse(m.toString('utf8'))
          m = m.msg if m.msg?
          if typeof m == "string"
            # console.log "exec #{m}"
            request = {}
            request.connection = ws
            request.from = "websocket"
            request.reply = (data)-> Bot.message {debug:data.trim()}
            Liq.command(request,m.split(' '))
          else if m.search?
            console.log "search #{m.search}"
            return child_process.exec "find #{PREFIX}/music|grep '#{m.search}'",
              (err,stdout,stderr) =>
                @message {search:{term:m.search,result:stdout}}
                # r = []; r.push i.substr(PREFIX.length+1) for i in stdout.trim().split("\n")
                # @message {search:{term:m.search,result:r.join("\n")}}
          else if m.login?
            console.log "login #{m.login.user}"
            if Bot.login(m.login)
              @login = true
              Web.sock.group['studio'].push ws
              return @message {msg:{login:true}}
            return @message {msg:{login:false}}
        catch e
          console.log e
      ws.on "end",   ()-> Web.sock.gone ws
      ws.on "error", ()-> Web.sock.gone ws

    @on "sendMessage", Web.sock.chancast

    console.log "web_init: done"