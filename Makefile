ERL=$(shell couch-config --erl-bin)
VERSION=$(shell git describe)
# Output ERL_COMPILER_OPTIONS env variable
COMPILER_OPTIONS=$(shell $(ERL) -noinput +B -eval 'Options = case os:getenv("ERL_COMPILER_OPTIONS") of false -> []; Else -> {ok,Tokens,_} = erl_scan:string(Else ++ "."),{ok,Term} = erl_parse:parse_term(Tokens), Term end, io:format("~p~n", [[{i, "${COUCH_SRC}"}] ++ Options]), halt(0).')
COMPILER_OPTIONS_MAKE_CHECK=$(shell $(ERL) -noinput +B -eval 'Options = case os:getenv("ERL_COMPILER_OPTIONS") of false -> []; Else -> {ok,Tokens,_} = erl_scan:string(Else ++ "."),{ok,Term} = erl_parse:parse_term(Tokens), Term end, io:format("~p~n", [[{i, "${COUCH_SRC}"},{d, makecheck}] ++ Options]), halt(0).')
ERLANG_VERSION=couch-config --erlang-version
PLUGIN_DIRS=ebin priv
PLUGIN_VERSION_SLUG=geocouch-$(VERSION)-$(ERLANG_VERSION)
PLUGIN_DIST=$(PLUGIN_VERSION_SLUG)

all: compile

compile:
	ERL_COMPILER_OPTIONS='$(COMPILER_OPTIONS)' ./rebar compile

compileforcheck:
	ERL_COMPILER_OPTIONS='$(COMPILER_OPTIONS_MAKE_CHECK)' ./rebar compile

buildandtest: all test

runtests:
	ERL_FLAGS="-pa ebin -pa ${COUCH_SRC} -pa ${COUCH_SRC}/../etap -pa ${COUCH_SRC}/../snappy" prove ./test/*.t

check: clean compileforcheck runtests
	./rebar clean

clean:
	./rebar clean
	rm -f *.tar.gz

geocouch-$(VERSION).tar.gz:
	git archive --prefix=geocouch-$(VERSION)/ --format tar HEAD | gzip -9vc > $@

dist: geocouch-$(VERSION).tar.gz

plugin: buildandtest
	mkdir -p $(PLUGIN_DIST)/
	cp -r $(PLUGIN_DIRS) $(PLUGIN_DIST)
	tar czf $(PLUGIN_VERSION_SLUG).tar.gz $(PLUGIN_DIST)
	@$(ERL) -eval 'File = "$(PLUGIN_VERSION_SLUG).tar.gz", {ok, Data} = file:read_file(File),io:format("~s: ~s~n", [File, base64:encode(crypto:sha(Data))]),halt()' -noshell
