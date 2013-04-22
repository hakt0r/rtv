# radio skeleton
songs    = audio_to_stereo(id="songs",playlist(id="songs","/#{RADIO}/music"))
jingles  = audio_to_stereo(id="jingles",playlist(id="jingles","/#{RADIO}/jingles"))
podcasts = audio_to_stereo(id="podcasts",playlist(id="podcasts","/#{RADIO}/podcasts"))

add_skip_command(podcasts)
add_skip_command(songs)
add_skip_command(jingles)

# the 24/7 schedule
radio = id(
  id="schedule",
  skip_blank(
    rotate(
      weights=[1,3,1,3],
      [jingles, songs, podcasts, songs])))

add_skip_command(radio)