###
  "RTV main-"module - part of the RTV project
  c) 2012 - 2013
    Sebastian Glaser <anx@ulzq.de>
  Licensed under GNU GPLv3
###

_devmock =
  admin:
    name: 'admin'
    password :'c0ntr0l' # devel
  xmpp:
    jid : 'radio@ulzq.de' # devel
    server : 'localhost' # devel
    password : 'r4d10' # devel
    room_jid: 'ulzquorum@conf.ulzq.de' # devel
    room_nick: 'rex'
  icecast:
    'source-password' : 'fr33d0m!' # devel
    'admin-password' : '*source_passwd*'
    'relay-password' : '*source_passwd*'
    port : 8000
  web:
    port : 8020
    websock : 8021
  liquify:
    server : "127.0.0.1"
    port : 1234
    rcvaddr : "127.0.0.1"
    rcvport : 8100

_schema = properties:
  admin:
    properties:
      name:
        default : 'admin'
        pattern: /^[a-zA-Z\s\-]+$/
        message: "Name must be only letters, spaces, or dashes"
        required: yes
      password:
        required: yes
        hidden: yes
  xmpp:
    properties:
      jid:
        pattern: /[^@]+@[a-zA-Z0-9_.\-]+$/
        message: "e.g. joe@example.com"
        required: yes
      server:
        default : '*as in jid*'
      password:
        required: yes
        hidden: yes
      room_jid:
        required: yes
      room_nick:
        default : 'rtv'
        required : yes
  icecast:
    properties:
      'source-password' :
        required: yes
      'admin-password' :
        default : '*source_passwd*'
      'relay-password' :
        default : '*source_passwd*'
      port:
        default : 8000
  web:
    properties:
      static : {default:8020}
      websock : {default:8021}
  liquify:
    properties:
      server :
        default : "127.0.0.1"
      port :
        default : 1234
      rcvaddr :
        default : "127.0.0.1"
      rcvport :
        default : 8100

_defaults = ->
  defaults =
    stream :
      radio : { ogg:off, mp3:off, aac:on }
      webradio : { ogg:on, mp3:off, aac:on }
    web :
      port : 8020
      websock : 8021
    icecast : {}
    database : { path : "#{@PREFIX}/etc/bot.db" }
    liquify :
      server  : "127.0.0.1"
      port    : 1234
      rcvport : 8100
  return defaults

_merge_cfg = (cfg,dft) ->
  return cfg unless typeof dft is "object"
  cfg = {} unless cfg?
  for k in Object.keys(dft)
    unless cfg[k]?
      if typeof dft[k] isnt "object"
        cfg[k] = dft[k]
      else cfg[k] = _merge_cfg(cfg[k],dft[k])
  return cfg

module.exports =
  defaults : _defaults
  bootstrap : (Bot,onfinish) ->
    # prompt = require 'prompt'
    # prompt.start()
    # prompt.get _schema, (err, r) ->
      r = _devmock
      r.icecast['admin-password'] = r.icecast['source-password'] if r.icecast['admin-password'] is '*source_passwd*'
      r.icecast['relay-password'] = r.icecast['source-password'] if r.icecast['relay-password'] is '*source_passwd*'
      r.xmpp.server = r.xmpp.jid.split('@').pop() unless r.xmpp.server isnt '*as in jid*'
      admin = r.admin; delete r.admin
      xmpp = r.xmpp; delete r.xmpp
      web = r.web; delete r.web
      r = _merge_cfg r, _defaults()
      r =
        web : web
        xmpp : xmpp
        rtv : r
        modules : [ 'xmpp', 'feed', 'rtv', 'rtv/liquify', 'rtv/web', 'rtv/youtube' ]
      Bot.config =_merge_cfg r, Bot.config
      console.log Bot.config.web
      for file in ["icecast.xml", "liquidsoap.liq"]
        fs.writeFileSync Bot.project+"/etc/"+file,
          require("../tpl/#{file}.coffee").call(Bot)
      onfinish(admin)
  init : ->