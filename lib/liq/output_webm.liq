# TODO: find realtime settings
output.icecast(
  %gstreamer(
    audio="aacenc",
    muxer="webmmux",
    video="vp8enc",
    threads=2,
    channels=2,
    log=5),
  id="video",
  icy_metadata="false",
  format="video/webm",
  mount="tv.aac",
  host=icecast_host,
  password=icecast_pass,
  video)