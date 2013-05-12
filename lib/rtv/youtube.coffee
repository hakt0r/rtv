###
  youtube module - part of the RTV project
  c) 2012 - 2013
    Sebastian Glaser <anx@ulzq.de>
  Licensed under GNU GPLv3
###

module.exports =
  libs :
    youtube : "youtube-feeds"
    youtubedl : "youtube-dl"
  init : ->
    { PREFIX } = this
    { fs, request, Liq } = @api

    @mediapath = "#{@project}/videos"
    @musicpath = "#{@project}/music"

    @new_command
      cmd   : "!wget"
      admin : true
      args  : true
      fnc   : (request, args) =>
        return unless args[0]?
        filename = args[0].split("/").pop()
        dl = request args[0]
          .on "error", (e) => request.reply "wget::error #{e}"
          .on "end", (e,r) => request.reply "wget::done #{@musicpath}/#{filename}" 
          .pipe(fs.createWriteStream("#{@musicpath}/#{filename}"))

    @new_command
      cmd   : "!yt"
      admin : true
      args  : true
      fnc   : (request, args) =>
        while args[0]? and args[0].match(/^-/)
          switch args[0]
            when "-s"
              args.shift()
              request.reply "searching: #{args.join(' ')}"
              youtube.feeds.videos {q:args.join('+')}, (err, result) =>
                if result? and result.items?
                  result = result.items.shift()
                  request.reply "*#{result.id}* #{result.title}"
              return
            when "-a" then audiorip= true
            when "-p" 
              audiorip= true
              autoplay= true
          args.shift()
        title = args[0]
        request.reply "yt: accepted(#{title})"
        youtubedl.info args[0], (err, info) =>
          if err
            request.reply "yt::error(#{args[0]}): #{err}"
            return
          title = info.title.
            replace(/[^ \-\(\)a-zA-Z0-9!?.]/g,"").
            replace("  "," ").
            replace("  "," ").
            replace(/^[^ a-zA-Z0-9]+/,"").
            trim()
          filename = "#{title.replace(/\ /g,".").replace(/[\(\)]/g,"-")}"
          request.reply "(youtube): #{title}\n#{info.description}"
          opts = ["--max-quality=18"]
          opts = opts.concat(["--extract-audio","--audio-format","mp3"]) if audiorip
          dl   = youtubedl.download(args[0],@mediapath,opts)
          dl.on "download", (data) => request.reply "yt::started: #{title}"
          dl.on "error",    (err)  => request.reply "yt::error #{err}"
          dl.on "end",      (data) =>
            try
              if audiorip
                filename = "#{filename}.mp3"
                fs.renameSync(
                  "#{@mediapath}/#{data.filename.replace(/.[^.]+$/,".mp3")}", 
                  "#{@musicpath}/#{filename}")
              else filename = filename + data.filename.replace(/^.*\./,'')
              if autoplay
                Liq.play "#{@musicpath}/#{filename}", (result) =>
                  request.reply "yt::enqueued #{title}" + 
                  "\n#{result}"
              else
                request.reply "yt::finished(#{title})" +
                  "\nFile: #{@musicpath}/#{filename}" +
                  "\nSize: #{data.size}" +
                  "\nTime: #{data.timeTaken}"
            catch err
              request.reply "yt::error #{err}"
            