###
  BEASTY WEBINTERFACE
    fame goes to express, ws, and webrtc
    tiamat was written for this
###

format = require("util").format

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
  deps : [ 'web', 'database', 'rtv/liquify' ]
  libs : [ 'express', 'ws', 'fs', 'tiamat', 'child_process', {
      WebRTC : 'webrtc.io', coffee : 'coffee-script', youtube : "youtube-feeds" } ]

  init : (config) ->
    { PREFIX } = this
    { Liq, Web, ws, child_process, tiamat, express, WebRTC, youtube, md5, json } = @api
    J = json
    WebSocketServer = ws.Server
    _bot = this
    _api = @api
    
    ## static web server
    webroot = "#{@project}/lib/rtv/web/root"
    app = Web
    app.use express.compress()
    app.use "/", express.static(webroot)

    ## file upload
    app.use express.bodyParser()
    app.post "/studio/upload", (req, res, next) ->
      # the uploaded file can be found as `req.files.image` and the
      # title field as `req.body.title`
      res.send format(
        "\nuploaded %s (%d Kb) to %s as %s",
        req.files.image.name,
        req.files.image.size / 1024 | 0,
        req.files.image.path,
        req.body.title)

    ## tiamat app compiler
    # @compile_page = tiamat
    # @compile_page # into one file
    #   compress     : on
    #   hashes       : no
    #   verbose      : yes
    #   recompile    : no # TODO: yes
    #   webroot      : webroot
    #   template     : "template.html"
    #   dest         : "#{webroot}/index.html"
    #   warn_missing : yes
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

    class RexWSS extends WebSocketServer
      # Static infrastructure
      @conns : []
      @group : {studio:[],meta:[],news:[]}
      @there : (ws) ->
        RexWSS.conns.push ws
        RexWSS.group['news'].push ws
        RexWSS.group['meta'].push ws
        console.log "ws:new_connection", RexWSS.group
      @gone  : (ws) ->
        delete RexWSS.conns[RexWSS.conns.indexOf(ws)]
        for group in Object.keys RexWSS.group
          if (i = RexWSS.group[group].indexOf ws) isnt -1
            delete RexWSS.group[group][i]
      @chancast : (msg) ->
        for dest, m of msg
          continue unless RexWSS.group[dest]
          grp = RexWSS.group[dest]
          m = JSON.stringify(J(dest,m))
          for key, ws of grp
            try
              console.log "to:", ws.from
              ws.send m
            catch e
              console.log "gone", e
              RexWSS.gone ws
      # Instance Elements
      fileid : 0
      constructor : (opts) ->
        _reply = console.error
        super opts
        _bot.on "sendMessage", RexWSS.chancast
        @on "connection", (ws) ->
          ws.login = false
          ws.file   = {} # UPLOAD
          ws.fileid = 0  # UPLOAD
          ws.binary_message = (id=0,segment=0,m)->
            ws.send '@'+id+':'+segment+':'+m.length+':'+m+'@'
          ws.message = (m) -> ws.send JSON.stringify(m)
          _reply = ws.message
          ws.request =
            handle : ws
            from : "websocket"
            reply : _reply
            public_reply : _bot.message
            private_reply : _reply
          ws.on "message", (m) -> 
            if m[0] isnt "@"
              try m = JSON.parse(m.toString('utf8'))
              catch e
                _reply {msg:{raw:e.toString()}}
              _api.route ws.request,m
            else
              idx = -1
              break for idx in [4...10] when m[idx] is '@'
              if idx isnt 10
                [ id, segment ] = m.slice(1,idx).toString('utf8').split(':')
                ws.file[id].stream.write new Buffer m.slice(idx+1), 'binary'
              else console.log "Malformed", m.slice(0,10).toString 'utf8'
          ws.on "end",   -> RexWSS.gone ws
          ws.on "error", -> RexWSS.gone ws
          RexWSS.there ws
        _api.register
          exec: (v) -> # context of a registered callback is a request ;)
            return Liq.command this, v.split(' ') if typeof v is "string"
            Liq.command this, i.split(' ') for i in v if Array.isArray v
          search: (s) ->
            if s.opts.indexOf('youtube') isnt -1
              youtube.feeds.videos {q:s.term.replace(/\ /g,'+')}, (err, result) =>
                if result? and result.items?
                  @reply {search:{term:s.term,kind:'youtube',result:result.items}}
            _find = (s,kind) =>
              child_process.exec "find #{_bot.project}/#{kind}|grep '#{s.term}'",
                (err,stdout,stderr) =>
                  @reply {search:{term:s.term,kind:kind,result:stdout.trim().split('\n')}}
            _find s,kind for kind in ['music', 'videos', 'podcasts', 'jingles'] when s.opts.indexOf(kind) isnt -1
          msg:
            login: (query) ->
              console.log "login #{query.user}"
              if _api.User.login(query)
                @from = query.user
                RexWSS.group['studio'].push @handle
                return @reply {msg:{login:true}}
              return @reply {msg:{login:false}}
            upload:done: (args) ->
              @handle.file[args.id].finish()
            upload:request: (file) ->
              file.path = path = "#{_bot.musicpath}/#{file.name}"
              file.id =  id = @handle.fileid++
              file.finish = =>
                stream.end()
                delete @handle.file[id]
              @handle.file[id] = file
              file.stream = stream = fs.createWriteStream file.path
              stream.on 'error', (error) => @reply msg:upload:error:error
              stream.on 'open',  (fd)    => @reply msg:upload:id:id

    Web.sock = new RexWSS({port:config.websock})
