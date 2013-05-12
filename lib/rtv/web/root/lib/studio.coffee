###
  Da Mighty Radio (DRM-E4)
    html5-only-go-fuck-yourselves-edition
###

class GuerillaStudio

  constructor : ->
    window.Studio = this

    api.register
      msg:raw: (m)-> console.log "RAW", m
      mode :
        live : (m)->
          ui.Master.out.state on
        off : (m)->
          ui.Master.out.state off
      search : (m)->
        return ui.Search.add_results m
      news : (m)->
        ticker = $('#news')
        e = document.createElement "p"
        e.innerHTML =
          "NEWS(<a href='#{m.news.source}'>quelle</a>) " + 
          "#{m.news.title} " + 
          "(<a href='#{m.news.link}'>link</a>)<br/>"
        ticker.insertBefore e, ticker.firstChild

  cli :
    usage : => "login [user] [pass]"
    echo  : (args,reply) => args.join(' ')
    login : (args,reply) => @login(args.shift(),args.join(' '))

  search : (term) =>
    api.socket.message {search:{opts:['music','youtube'],term:term}}

  exec : ->
    if api.socket?
      for m in arguments
        console.log 'exec', m
        if typeof m is "string" then api.socket.message({exec:m})
        else api.socket.message(m)

  toggle_broadcast : => @exec "go live"

  toggleGUI : =>
      if $("#windows").css("display") is "none"
        $("#windows").css("display","block")
        @resize_faders()
        return true
      $("#windows").css("display","none")
      return false

  initGUI : =>
    window.ui = {}

    # CONSOLE :: refac
    window.my_console = $("#out").console
      promptLabel: "anx@radio> "
      commandValidate: (line) => true
      commandHandle: (data,reply) => 
        line = data.split(' ')
        cmd  = line.shift()
        return Studio.cli[cmd].call(api,line,reply) if Studio.cli[cmd]?
        Studio.exec data; true
      autofocus: true
      animateScroll: true
      promptHistory: true
    $("#out").on "focus", () ->          $("#console").css("bottom","0px")
    $("#console").on "mouseleave", () -> $("#console").css("bottom","-190px")
    $("#console").on "mouseenter", () ->
      $("#console").css("bottom","0px")
      $("#out")[0].focus()

    # MENU BUTTONS
    new UIButton
      id : "studio"
      parent : "#menu"
      tooltip : "Open studio window"
      hide : true
      class : "framed studio"
      click : -> if Studio.toggleGUI() then @query.addClass('on') else @query.removeClass('on')
      init  : -> @hide()

    new UIButton
      id : "search"
      parent : "#search-grp"
      class : "framed list"
      tooltip : "Toggle search-results display"
      click : ->
        r = $ '#results'
        if r.css('display') is 'none'
          r.css 'display','block'
          @query.addClass 'on'
        else
          @query.removeClass 'on'
          r.css 'display','none'

    for kind in ['youtube','music','videos','podcasts','jingles']
      new UIButton
        parent : "#search-grp"
        id : "search-#{kind}"
        tooltip : "Toggle #{kind}-search"
        class : "framed float-right #{if kind is 'youtube' then 'notube' else kind}"
        click : ->
          r = $ '#results'
          if @query.hasClass 'on'
            @query.removeClass 'on'
            r.find('.'+kind).css 'display','none'
          else
            @query.addClass 'on'
            r.find('.'+kind).css 'display','block'

    # SETUP SLIDERS
    $(".fader.horizontal").slider(
      animate : true
      min : 0
      max : 100)

    # UI::GLUE::SEARCH
    ui.Search =
      field : $("#search")
      add_result : (el,uri) =>
        reset = () =>
          $("#results").css("display","none")
          ui.Left.playlist.removeClass("clickme")
          ui.Right.playlist.removeClass("clickme")
          ui.Left.playlist.off "click"
          ui.Right.playlist.off "click"
        ui.Left.playlist.addClass("clickme")
        ui.Right.playlist.addClass("clickme")
        ui.Left.playlist.on("click", () =>
          reset()
          ui.Left.push(uri))
        ui.Right.playlist.on("click", () =>
          reset()
          ui.Right.push(uri))
      add_results : (search) =>
        console.log "search.results"
        results = $("#results")
        results.css("display","block")
        results.css("position","fixed")
        for l in search.result
          if search.kind is "youtube"
            t = "#{l.title}"
            s = "ui.Search.add_youtube('#{l.id}')"
          else
            t = cleanup_filename(l)
            s = "ui.Search.add_result(this,'#{l}')"
          results.append """<a href="#" onclick="#{s}" class="#{search.kind} result">#{t}</a>\n"""
        results.find("a").css("display","block")
    ui.Search.field.keypress (evt) =>
      if evt.which == 13
        console.log "search #{ui.Search.field.val()}"
        @search(ui.Search.field.val())
        return false
      true
    ui.Search.field.sortable
      connectWith: ".draggy"

    # UI::GLUE::DECKS
    ui.Left = new Deck("left")
    ui.Right = new Deck("right")

    # UI::GLUE::MIXERS
    ui.Master = new Mixer
      resource : "master"
      tooltip : "Master-mixer / Broadcast control"
      output :
        class   : "signal"
        tooltip : "Toggle broadcasting"
        action  : => @exec "go live-toggle"
      inputs :
        0 : "music"
        1 : "dj"
        2 : "conf"
        3 : "voip"

    ui.Monitor = new Mixer
      tooltip : "Monitor-mixer"
      resource : "monitor"
      output:
        class : "monitor"
        tooltip : "Toggle monitor"
        action : => @exec "monitor.toggle"
      inputs :
        0 : "music"
        1 : "dj"

    # UI::GLUE::MODULES
    ui.Xfade = new Module("#xfade-grp")
    ui.Xfade.fader.on "slide", (evt,ui) -> Studio.exec("fade set #{ui.value}")
    ON "#broadcast", "click", -> Studio.toggle_broadcast()

    # resize .fader.horizontal
    @resize_faders = -> $("#decks .fader.vertical").css "height", ($(".playlist").height()-43) + "px"
    $(window).on "resize", @resize_faders

$(document).ready () -> new GuerillaStudio()