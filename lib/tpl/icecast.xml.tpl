<icecast>
    <limits>
        <clients>100</clients>
        <sources>10</sources>
        <threadpool>10</threadpool>
        <queue-size>524288</queue-size>
        <client-timeout>3</client-timeout>
        <header-timeout>5</header-timeout>
        <source-timeout>3</source-timeout>
        <burst-on-connect>1</burst-on-connect>
        <burst-size>65535</burst-size>
    </limits>
    <authentication>
        <source-password>fr33d0m!r4d10</source-password>
        <relay-password>fr33d0m!r4d10!r3l41s</relay-password>
        <admin-user>admin</admin-user>
        <admin-password>fr33d0m!4dm1n</admin-password>
    </authentication>
    <!-- directory>
        <yp-url-timeout>15</yp-url-timeout>
        <yp-url>http://dir.xiph.org/cgi-bin/yp-cgi</yp-url>
    </directory> -->
    <hostname>radio.ulzq.de</hostname>
    <listen-socket>
        <port>8000</port>
    </listen-socket>
    <mount>
        <mount-name>/radio.ogg</mount-name>
        <fallback-mount>/panic.ogg</fallback-mount>
        <fallback-override>1</fallback-override>
    </mount>
    <mount><mount-name>/panic.ogg</mount-name></mount>
    <mount>
        <mount-name>/radio.mp3</mount-name>
        <fallback-mount>/panic.mp3</fallback-mount>
        <fallback-override>1</fallback-override>
    </mount>
    <mount><mount-name>/panic.mp3</mount-name></mount>
    <fileserve>1</fileserve>
    <paths>
        <basedir>/usr/share/icecast2</basedir>
        <logdir>/var/log/icecast2</logdir>
        <webroot>/usr/share/icecast2/web</webroot>
        <adminroot>/usr/share/icecast2/admin</adminroot>
        <alias source="/" dest="/status.xsl"/>
    </paths>
    <logging>
        <accesslog>access.log</accesslog>
        <errorlog>error.log</errorlog>
      	<loglevel>1</loglevel>
      	<logsize>10000</logsize>
    </logging>
    <security>
        <chroot>0</chroot>
    </security>
</icecast>