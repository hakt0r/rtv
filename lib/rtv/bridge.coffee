NET = require 'net'

class LiquidSock
  constructor : (options={}) ->
    { @id, @server, @port, @onerror, @imgone, @imready, @cmd, @callback } = options
    # @onerror = # console.log unless @onerror?
    @sock  = NET.connect(@port,@server)
      .on('connect',@connect)
      .on('data',@data)
      .on('end',@end)
      .on('error',@error)
  connect : =>
    @buffer = ""
    return @try() if @cmd? # and @cmd != null
    @reset()
  reset : =>
    @buffer = ""
    @cmd = @callback = null
    @ready = true
    # console.log "READY[#{@id}]"
    return unless @imready(this)
    # console.log "BASTARD[#{@id}]"
    @imgone(this)
    @sock.destroy()
  end : =>
    @ready = false; # console.log "END[#{@id}]"
    @imgone(this)
  error : (err) =>
    @ready = false; console.log "ERROR[#{@id}]: #{err}"
    @onerror @cmd, @callback if @cmd?
    @imgone(this)
  try : (cmd,callback) =>
    # console.log "TRY[#{@id}]: #{cmd.trim() if cmd?}"
    if cmd?
      unless @ready
        # # console.log "ICANT[#{@id}]: #{@cmd.trim()}"
        return false
      # # console.log "ICAN[#{@id}]: #{cmd.trim()}"
      @cmd = cmd
      @callback = callback
    if @cmd
      # # console.log "IMTRYING[#{@id}]: #{@cmd.trim()}"
      @ready = false
      # # console.log "WRITE[#{@id}]: #{@cmd.trim()}"
      try
        @sock.write @cmd
      catch err
        console.log "ERROR[#{@id}]: #{err} retry #{cmd}", typeof cmd
        @error()
  data : (data) =>
    data = data.toString("utf-8")
    # # console.log "RAW[#{@id}]: '#{data.trim()}'"
    # if @cmd == null or !@callback?
    #   # console.log "ERROR[#{@id}]: Not expecting data but look: '#{data.trim()}'"
    #   return
    @buffer += data
    if @buffer.indexOf("END") isnt -1
      data = @buffer.replace("\r\n","\n").trim()
      return unless data.substr(data.length-3) == "END"
      data = data.substr(0,data.length-4)
      if @callback?
        # console.log "DONE[#{@id}]: '#{data}'"
        return @reset(@callback(data))
      else
        # console.log "ERROR[#{@id}]: No callback for '#{@cmd}'"
        return @error()
    # else # console.log "PART[#{@id}]: '#{data.trim()}'"

class LiquidBridge
  constructor : (options={}) ->
    { @smin, @debug, @server, @port } = options
    for name, val of options
      if typeof val is "function"
        # console.log "LiquidBridge::add_function #{name}"
        this[name] = val
    @readycount = 0
    @sid    = 1
    @smin   = 2           unless @smin?
    @smax   = 5           unless @smax?
    @server = "127.0.0.1" unless @server?
    @port   = 1234        unless @port?
    @sock   = {}
    @queue  = []
    @add_sock = (cmd,callback) =>
      if Object.keys(@sock).length < @smax
        # console.log  "CREATE[#{@sid}]"
        @sock[@sid] = sock = new LiquidSock
          id:       @sid++
          cmd:      cmd
          callback: callback
          server:   @server
          port:     @port
          onerror:  @execute
          imgone:   @socket_gone
          imready:  @socket_ready
      else if cmd?
        @queue.push [cmd,callback]
        # console.log "ENQUEUE(#{Object.keys(@sock).length}/#{@smax}:#{@queue.length}): #{cmd.trim()}"
      else # console.log "OOOOOOOPS#1"
    @socket_ready = (sock) =>
      if @queue.length > 0
        [cmd, callback] = @queue.shift()
        sock.try(cmd, callback)
      return true if @readycount > @smax
      # console.log "SOCKET READY: ready: #{@readycount} -> #{@readycount+1} (#{Object.keys(@sock).length} sockets)"
      @readycount++
      return false
    @socket_gone = (sock) =>
      # console.log "SOCKET GONE: ready: #{@readycount} -> #{@readycount-1} (#{Object.keys(@sock).length} sockets)"
      delete @sock[sock.id]
      @readycount--
      @add_sock() unless @readycount > @smax
    @execute = (cmd,callback) =>
      if typeof callback != "function"
        console.log "ERROR: LiquidBridge: NO CALLBACK FOR #{cmd}"
        return false
      switch typeof cmd
        when "string"
          # console.log "EXEC: #{cmd.trim()}, #{typeof callback}"
          cmd += "\n"
          return s.try(cmd,callback) for k,s of @sock when s.ready
          @add_sock(cmd,callback)
        when "object", "array"
          ctx = 
            callback : callback
            cmds : cmd
            results : []
            done : 0
            time : Date.now() / 1000
          i=0
          # console.log "BRANCH", ctx.cmds
          for a in cmd
            @branch a,ctx,i++
        # else console.log "INVALID type: #{typeof cmd}" 
    @join = (result,ctx,ord) =>
      ctx.done++
      ctx.results[ord] = result
      if ctx.done >= ctx.cmds.length
        # console.log "JOINED", ctx.cmds
        ctx.callback(ctx.results)
    @branch = (cmd,ctx,ord) =>
      @execute cmd, (result) => @join result, ctx, ord
    @add_sock() for i in [0..(@smin-1)]

module.exports = LiquidBridge