window.globalize_ids = (arr) -> # doubly politically incorrect function
  for k in arr
    e = document.querySelector "#"+k
    window[k] = e if e?

window.TEXT = (sel) ->
  document.querySelector(sel).value

window.ON = (sel,evt,cb) ->
  el = document.querySelector(sel)
  el.addEventListener evt, cb if el?

window.cleanup_filename = (l)->
  return l.
    split("/").
    pop().
    replace(".mp3","").
    replace(".ogg","").
    replace(/\./g," ").
    replace(/_/g," ").
    replace(/^[0-9]+ -/," ").
    replace(/^[0-9]+ /," ").
    replace(/-$/," ").
    trim()

window.meta_to_title = (m) ->
  t = "ulzq radio"
  t = m.title           if m.title?
  t += " - #{m.artist}" if m.artist?
  t += " (#{m.source})" if m.source?
  return t

window.Dialog =
  hide : (sel) =>
    $("#dialogs").hide()
    $(sel).hide()
  show : (sel) =>
    console.log "show #{sel}"
    $("#dialogs").show()
    $(sel).show()

String.prototype.sha512 = (d) -> SHA512(d)
String.random = (length) ->
  chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  result = ''; i = length
  result += chars[Math.round(Math.random() * (chars.length - 1))] while i-- > 0
  result

class AnonymousApi
  _handle : {}
  constructor : (@address,@service) ->
  register : (opts={}) =>
    @_handle[k] = v for k,v of opts
  connect: =>
    @socket  = new WebSocket(@address,@service)    if WebSocket?
    @socket  = new MozWebSocket(@address,@service) if MozWebSocket?
    @socket.message   = (m) -> @send(JSON.stringify({msg:m}))
    @socket.onerror   = (s) ->
      console.log "sock:error #{s}"
      @connect()
    @socket.onopen    = (s) ->
      console.log "sock:connected"
      # Studio.login("ghost","muh")
    @socket.onmessage = (m) =>
      try @route JSON.parse(m.data)
      catch e
        console.log {}, e, m
  route : (m,rule) =>
    rule = @_handle unless rule?
    # console.log m, rule
    for k,v of m when rule[k]?
      # console.log k,v,rule[k]
      if typeof rule[k] is "function"
        rule[k].call(null,v)
        continue
      else
        @route v, rule[k]

class UIButton
  @byId = {}
  constructor : (opts={})->
    { @parent, @click, @init, @register, @class, @id, @title, hide } = opts
    @parent = document.querySelector(@parent)
    @title = @id unless @title?
    @class = @id unless @class?
    $(@parent).append("""<button class="#{@class}" id="#{@id}-btn">#{@title}</button>""")
    @query = $("##{@id}-btn")
    @query.hide() if hide? and hide is true
    @query.on "click", @click if @click?
    UIButton.byId[@id] = this
    @init() if @init?
  show : => @query.show()
  hide : => @query.hide()

window.UIButton = UIButton
window.api = new AnonymousApi("ws://ulzq.de:8021/radio", "radio")