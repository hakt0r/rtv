# # override metadata
# meta  = insert_metadata(id="meta_insert", radio)
# radio = snd(meta)
# meta  = fst(meta)
# def meta.set(data)
#   data = string.split(separator=" ",data)
#   key  = list.hd(data)
#   data = list.remove(key,data)
#   data = string.concat(separator=" ",data)
#   meta([(key,data)])
#   "END"
# end
# server.register("meta", meta.set )

# fix up metadata
def meta.fallback.title(m)
  title = m['title']
  [("title",(
    if(title=="") then
      t = basename(m['filename'])
      # t = string.replace(pattern="\.[^.]+$",fun(a)->"",t)
      t
    else title end ))]
end
def meta.fallback.artist(m)
  artist = m['artist']
  [("artist",(if(artist == "") then "now playing" else artist end ))]
end
def meta.fallback.album(m)
  album = m['album']
  [("album",(if(album == "") then "ulzq radio" else album end ))]
end
radio = map_metadata(meta.fallback.title, radio)
radio = map_metadata(meta.fallback.album, radio)
radio = map_metadata(meta.fallback.artist, radio)

# metadata routing (to bot)
radio = on_track(
  id="meta-event",
  fun (m)-> message([("meta",m)]),
  radio)