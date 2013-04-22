#!/usr/bin/liquidsoap
system("lsof -i -P -n | grep LISTEN | awk '/1234/{system(\"kill -9 \"$2)}'")

# enable_replaygain_metadata()
set("server.telnet", true)
set("server.telnet.port", 1234)
set("frame.video.channels",0)
set("log.level",1)

RADIO       = "/var/radio"
base_path   = RADIO
source_path = RADIO
bin_path    = base_path ^ "/bin"
inc_path    = base_path ^ "/liq"
icecast_pass="fr33d0m!r4d10"
icecast_host="localhost"

# mark config labels optional
ignore(bin_path)
ignore(inc_path)
ignore(source_path)
ignore(icecast_pass)
ignore(icecast_host)
# mark config labels optional

%include "/var/radio/liq/library.liq"

# activate one of the following as a base source
# %include "/var/radio/liq/fallback.liq"
%include "/var/radio/liq/schedule.liq"

# play request-queue
%include "/var/radio/liq/player.liq"

# live sink
%include "/var/radio/liq/live.liq"

# announcer
# %include "/var/radio/liq/announce.liq"

# disable this if you dont need it
# the jack wallclock is expensive 
%include "/var/radio/liq/studio.liq"

# metadata hackery
%include "/var/radio/liq/metadata.liq"

# video is quite expensive (think a dedicated core)
# %include "/var/radio/liq/video.liq"

# Output Formats
#out.ogg(start=true,"radio",radio)
#out.mp3(start=true,"radio",radio)
out.aac(start=true,"radio",radio)

# Strip metadata for webradio
nometa = drop_metadata(radio)
# out.mp3(start=true,"web",nometa)
out.ogg(start=true,"web",nometa)
out.aac(start=true,"web",nometa)