# just a scribble for the later refactoring
class Deck
  _volume : 100
  _status : "stop"
  constructor : (@api,@name) ->
    console.log "liq::deck_create(#{@name})"
  volume : (@value) ->
    @api.execute "#{name}.push #{uri}"
  push : (uri,request) ->
    @api.execute "#{name}.push #{uri}"
  insert : (uri,pos,request) ->
    @api.execute "#{name}.insert #{pos} #{uri}"
  remove : () ->
    @api.execute "#{name}.remove #{uri}"