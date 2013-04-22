# announcer

announce = audio_to_stereo(request.queue(id="announce"))
radio = smooth_add(
  normal=radio,
  special=announce)

radio = id(id="add-anounce",radio)
