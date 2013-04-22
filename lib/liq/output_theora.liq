output.icecast(
  %ogg(%vorbis,%theora(quality=30)),
  id="video",
  fallible=true,
  mount="tv.ogg",
  host=icecast_host,
  password=icecast_pass,
  video)