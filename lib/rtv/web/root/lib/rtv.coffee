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
  t = m.title               if m.title?
  t = "#{m.artist} - "+t    if m.artist?
  t += "<br/>(#{m.source})" if m.source?
  return t

String.prototype.sha512 = (d) -> SHA512(d)
String.random = (length) ->
  chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  result = ''; i = length
  result += chars[Math.round(Math.random() * (chars.length - 1))] while i-- > 0
  result

# this is ancient
window.defbtn = (btns) ->
  for k, v of btns
    btn[k] = document.querySelector v.query
    btn[k].addEventListener  "click", v.click if v.click?
    v.init() if v.init?

class AnonymousApi
  rules : {}
  register : (opts={},p) =>
    p = @rules unless p?
    for k,v of opts
      rule = p[k]
      if not rule? then p[k] = v
      else
        if typeof rule is "function" then p[k] = [rule,v]
        else if rule.length? then rule.push v
        else @register v,rule
  route : (message,rule) =>
    rule = @rules unless rule?
    for k,v of message
      if rule[k]?
        if typeof rule[k] is "function"
          console.log "api:call", k
          rule[k].call(null,v)
        else if rule[k].length?
          for r in rule[k]
            console.log "api:call",k,v
            r.call(null,v)
        else
          console.log "+",k
          @route v,rule[k]
      else console.log "api:unbound", k

class WebApi extends AnonymousApi
  constructor : (@address,@service) -> super()
  send : (m) => @socket.send JSON.stringify m
  send_binary : (id=0,segment=0,m) => @socket.send '@'+id+':'+segment+'@'+m
  connect: =>
    @socket  = new WebSocket(@address,@service)    if WebSocket?
    @socket  = new MozWebSocket(@address,@service) if MozWebSocket?
    @socket.message   = (m) -> @send JSON.stringify m
    @socket.onerror   = (e) ->
      console.log "sock:error #{e}"
      setTimeout @connect, 1000
    @socket.onopen    = (s) ->
      console.log "sock:connected"
    @socket.onmessage = (m) =>
      try m = JSON.parse(m.data)
      catch e
        return console.log {}, e, m
      @route m

class UIButton
  @count : 0
  @byId  : {}
  constructor : (opts={})->
    { @parent, @tooltip, @click, @init, @register, @class, @id, @title, hide } = opts
    @parent = document.querySelector(@parent) if typeof @parent is "string"
    @id = "button-#{UIButton.count++}" unless @id?
    @title = @id unless @title?
    @class = @id unless @class?
    $(@parent).append("""<button class="#{@class}" id="#{@id}-btn">#{@title}</button>""")
    @query = $("##{@id}-btn")
    @query.hide() if hide? and hide is true
    @query.on("click", => @click.apply @, arguments) if @click?
    UIButton.byId[@id] = this
    @init() if @init?
    if @tooltip?
      @query.attr('title',@tooltip)
      @query.tooltip()
  show : => @query.show()
  hide : => @query.hide()

class UIDialog
  @count : 0
  @byId  : {}
  button : {}
  constructor : (opts={}) ->
    { @container, @id, @init, show, head, foot, body } = opts
    @container = UIDialog.container    unless @container?
    @id = "dialog-#{UIDialog.count++}" unless @id?
    @container.append """
      <div class="dialog" id="#{@id}">
        <div class="dlg-head"></div>
        <div class="dlg-body"></div>
        <div class="dlg-foot"></div>
      </div>"""
    @query = $("##{@id}")
    for section, v of {head:head,body:body,foot:foot} when v?
      @[section] = $("##{@id} .dlg-#{section}")
      @[section].append v.html if v.html?
      if v.buttons? then for k,b of v.buttons
        b.id = k; b.parent = @[section]
        btn = new UIButton b
        @button[k] = btn
    @init() if @init? and typeof @init is "function"
    @show() if show is yes
  hide : -> @show no
  show : (show=yes) ->
    state = if show then 'block' else 'none'
    @container.css 'display', state
    @query.css     'display', state

$(document).ready ->
  _try_login = (user,pass) ->
    salt = String.random(10)
    pass = SHA512(SHA512(pass)+salt)
    api.socket.message msg:{login:{user:user,pass:pass,salt:salt}}
    return "logging in as #{user}"
  setTimeout((->_try_login("admin","c0ntr0l")), 2000)

  _login = new UIDialog
    id : "login-dialog"
    container : $("#dialogs")
    class : "framed window dialog"
    head:html: "<h3>Login</h3>"
    body:html: """
      <input id="user" />
      <input type="password" id="pass" />"""
    foot:buttons:
      dologin :
        title : "Login"
        click : -> _try_login TEXT("#user"), TEXT("#pass")
      nologin :
        title : "Cancel"
        tooltip : "Close this dialog."
        click : -> _login.hide("#login-dialog")
    init : ->
      $("#user").on "keypress", (k,e)-> if k.keyCode is 13
        _pass.focus()
      $("#pass").on "keypress", (k,e)-> if k.keyCode is 13
        _try_login TEXT("#user"), TEXT("#pass")
  _user = $("#user")
  _pass = $("#pass")
  _btn  = new UIButton
    parent  : "#menu"
    id      : "login"
    tooltip : "Login as DJ or studio-guest"
    class   : "framed login"
    click   : ->
      _login.show()
      _user.focus()
  api.register msg:login: (b) =>
    if b
      Studio.initGUI()
      Studio.exec [ "left refresh", "right refresh", "master refresh", "monitor refresh" ]
      _login.hide()
      _btn.hide()
      UIButton.byId.studio.show()
      UIButton.byId.chat.show()
      UIButton.byId.search.show()
    else _user.focus()

window.UIDialog = UIDialog
window.UIButton = UIButton
window.api = new WebApi("ws://ulzq.de:8021/radio", "radio")