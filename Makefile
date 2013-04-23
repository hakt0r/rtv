PATH := node_modules/.bin:${PATH}

deps:
	git submodule init;
	git submodule update;
	npm install;
	cd lib/rex; npm install

liquidsoap:
	env icecast;

icecast:
	env icecast;
