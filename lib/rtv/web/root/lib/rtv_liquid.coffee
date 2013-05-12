###
  Liquidsoap Widgets
###

J = window.json

class Module
  constructor : (selector) ->
    @query = $(selector)
    @button = @query.find("button")
    @fader = @query.find(".fader")

class Fader
  volumestate = false
  constructor : (@query,resource) ->
    @query = @query.find(".#{resource}-grp")
    @button = @query.find("button")
    @fader = @query.find(".fader")
    @fader.slider(
      orientation : "vertical"
      animate : true
      min : 0
      max : 100)
    @fader.slider("value",100)    
  value : (v) =>
    if v? then @fader.slider("value",v)
    else return @fader.slider("value")
    @state (v > 0) if @volumestate
  state : (@selected) ->
    if @selected is on
      console.log on
      @button.addClass("on")
      @button.removeClass("off")
    else
      @button.addClass("off")
      @button.removeClass("on")

class MixerInput extends Fader
  constructor : (@id,@parent,resource) ->
    super(@parent.query,resource)
    @button.on "click", () =>
      Studio.exec "#{@parent.resource} select #{@id} #{if @selected then false else true}"
    @fader.on "slide", (evt,ui) => Studio.exec("#{@parent.resource} volume #{@id} #{ui.value}")

class MixerOutput extends Fader
  constructor : (@parent,resource) ->
    super(@parent.query,resource)
    @fader.on "slide", (evt,ui) => Studio.exec("#{@parent.resource} volume.out #{ui.value}")

class Mixer
  constructor : (options={}) ->
    { @resource, @inputs, @action, @output, @tooltip } = options
    selector = "##{@resource}-mix"
    $(selector).append """<div class="framed mixer-grp"></div>"""
    @query = _query = $(selector)
    @col = new UIButton
      parent : "#menu"
      tooltip : @tooltip
      class : "framed #{@output.class} collapse"
      click : ->
        q = _query.find("> div")
        return q.css("display","none") unless q.css("display") == "none"
        return q.css("display","block")
    @group = @query.find(".mixer-grp")
    # output
    @group.append """
      <div class="fader-grp out-grp main">
        <button class="framed #{@output.class}">#{@output.caption}</button>
        <div class="fader vertical out-fdr"></div>
      </div>"""
    @out = new MixerOutput(this,"out")
    @out.button.on "click", @output.action if @output.action?
    @out.button.attr('title',@output.tooltip).tooltip() if @output.tooltip?
    # inputs
    @byId  = {}
    for id, resource of @inputs
      # console.log "+ input##{id} #{resource}"
      @group.append """
        <div class="fader-grp #{resource}-grp">
          <button class="framed #{resource}">#{resource}</button>
          <div class="fader vertical #{resource}-fdr"></div>
        </div>"""
      @byId[id] = this[resource] = new MixerInput(id,this,resource)
    @message = (m) =>
      m = m.refresh if m.refresh?
      if m.output?
        @out.value(parseInt(m.output))
      if m.state?
        @byId[m.state.id].state m.state.selected == "true"
        if @byId[m.state.id].value != m.state.volume
          @byId[m.state.id].value parseInt(m.state.volume)
      if m.input?
        for i,v of m.input
          @byId[i].value(parseInt(v.volume))
          @byId[i].state v.selected == "true"
    reg = studio:{}
    reg.studio[@resource] = @message
    api.register reg

class DeckVolume extends Fader
  constructor : (@parent,res) ->
    super(@parent.query,res)
    @button.on "click", () =>
      val = @fader.slider("value")
      if val > 0
        @old = val; Studio.exec "#{@parent.name} volume 0"
      else Studio.exec "#{@parent.name} volume #{@old}"
    @fader.on "slide", (evt,ui) => Studio.exec("#{@parent.name} volume #{ui.value}")

class Deck
  @lastid : 0
  constructor :  (@name) ->
    selector  = "##{@name}-deck"
    $(selector).replaceWith """
      <div class="framed deck #{@name}" id="#{@name}-deck">
        <div class="fader-grp #{@name}-grp main">
          <button class="framed mute">mute</button>
          <div class="fader vertical" id="#{@name}-fdr"></div>
        </div>
        <div class="deck-#{@name}-side">
          <div class="playback">
            <button class="framed play">play</button>
            <button class="framed pause">pause</button>
            <button class="framed stop">stop</button>
            <button class="framed refresh">refresh</button>
            <button class="framed add">add</button>
            <button class="framed del">del</button>
            <div class="track-title">nothing - #{@name}</div>
          </div>
          <div class="framed draggy playlist" id="#{@name}-lst"></div>
        </div>
      </div>"""
    @id       = Deck.lastid++
    @query    = $(selector)
    @volume   = new DeckVolume(this,@name)
    @playlist = @query.find(".playlist")
    @title    = @query.find(".track-title")
    @play     = @query.find(".play")
    @pause    = @query.find(".pause")
    @stop     = @query.find(".stop")
    @add      = @query.find(".add")
    @del      = @query.find(".del")
    @refresh  = @query.find(".refresh")
    @play.on  "click", () => Studio.exec("#{@name} play")
    @pause.on "click", () => Studio.exec("#{@name} pause")
    @stop.on  "click", () => Studio.exec("#{@name} stop")
    @refresh.on  "click", () => Studio.exec("#{@name} refresh")
    @playlist.sortable
      connectWith : ".draggy"
      update : (evt,ui) =>
        rid = parseInt(ui.item.attr("remoteid"))
        arr = @playlist.find("div").map () -> return parseInt($(this).attr "remoteid")
        pos = arr.toArray().indexOf(rid)
        Studio.exec("#{@name} move #{rid} #{pos}")
    @message = (m) =>
    reg = studio:{}
    reg.studio[@name] =
        volume: @volume.value
        refresh: (files) =>
          @playlist.empty()
          for rid, meta of files when meta.filename?
            @playlist.append("<div>#{cleanup_filename(meta.filename)}</div>")
        meta: (e) =>
          @title.text(cleanup_filename(e.filename))
          @title.effect("highlight",{color:"#662"},500)
        play: =>
          @play.addClass("on")
          @pause.removeClass("on")
          @stop.removeClass("on")
        pause: =>
          @pause.addClass("on")
          @play.removeClass("on")
          @stop.removeClass("on")
        stop: =>
          @stop.addClass("on")
          @play.removeClass("on")
          @pause.removeClass("on")
        push: (e) =>
          @playlist.append("<div remoteid='#{e.rid}'>#{cleanup_filename(e.meta.filename)}</div>")
    api.register reg
  push   : (uri)    -> Studio.exec("#{@name} push #{uri}")
  insert : (uri,at) -> Studio.exec("#{@name} insert #{at} #{uri}")
  remove : (at)     -> Studio.exec("#{@name} remove #{at} #{uri}")

window.Module = Module
window.Fader = Fader
window.MixerInput = MixerInput
window.MixerOutput = MixerOutput
window.Mixer = Mixer
window.DeckVolume = DeckVolume
window.Deck = Deck