APACHE_URL=	https://github.com/apache/httpd
APACHE_VER=	2.4.51

WITH_SSL?=	$(HOME)/local/babassl

CFLAGS=		-g -std=c99 -pipe -O2 -Wall
CFLAGS+=	-D_REENTRANT -D_GNU_SOURCE -D_LARGEFILE64_SOURCE
CFLAGS+=	-Ideps/include/apr-1 -I$(WITH_SSL)/include

LDFLAGS=	-Ldeps/lib -L$(WITH_SSL)/lib
LDFLAGS+=	-Wl,-Bstatic -lapr-1 -laprutil-1 -lssl -lcrypto \
		-Wl,-Bdynamic -lm -ldl -pthread

all: ab

ab: src deps ap_config_auto.h
	$(CC) $(CFLAGS) -o ab ab.c $(LDFLAGS)

ap_config_auto.h:
	@echo "#define HAVE_OPENSSL" > $@

.PHONY: src
src: ab.c ap_release.h ab.1
ab.c:
	wget -O $@ $(APACHE_URL)/raw/$(APACHE_VER)/support/$@
ap_release.h:
	wget -O $@ $(APACHE_URL)/raw/$(APACHE_VER)/include/$@
ab.1:
	wget -O $@ $(APACHE_URL)/raw/$(APACHE_VER)/docs/man/$@

#----------------------------------------------------------------------------

APR_MIRROR=	https://dlcdn.apache.org
APR_VER=	1.7.0
APR_UTIL_VER=	1.6.1

.PHONY: deps
deps: apr apr-util
apr: deps/lib/libapr-1.a
apr-util: apr deps/lib/libaprutil-1.a

deps/lib/libapr-1.a: deps/apr
	cd deps/apr && \
		./configure --prefix=$(CURDIR)/deps --disable-shared && \
		make && \
		make install

deps/lib/libaprutil-1.a: deps/apr-util
	cd deps/apr-util && \
		./configure --prefix=$(CURDIR)/deps --with-apr=$(CURDIR)/deps && \
		make && \
		make install

deps/apr: deps/apr-$(APR_VER).tar.gz
	cd deps && \
		tar -xf apr-$(APR_VER).tar.gz
	[ ! -e deps/apr ] || rm -f deps/apr
	ln -s apr-$(APR_VER) deps/apr

deps/apr-util: deps/apr-util-$(APR_UTIL_VER).tar.gz
	cd deps && \
		tar -xf apr-util-$(APR_UTIL_VER).tar.gz
	[ ! -e deps/apr-util ] || rm -f deps/apr-util
	ln -s apr-util-$(APR_UTIL_VER) deps/apr-util

deps/apr-$(APR_VER).tar.gz:
	@[ -d "deps" ] || mkdir deps
	wget -O $@ $(APR_MIRROR)/apr/apr-$(APR_VER).tar.gz

deps/apr-util-$(APR_UTIL_VER).tar.gz:
	@[ -d "deps" ] || mkdir deps
	wget -O $@ $(APR_MIRROR)/apr/apr-util-$(APR_UTIL_VER).tar.gz

#----------------------------------------------------------------------------

.PHONY: clean
clean:
	rm -f ab ap_config_auto.h
	rm -f deps/apr deps/apr-util
	rm -rf deps/apr-$(APR_VER) deps/apr-util-$(APR_UTIL_VER)

.PHONY: cleanall
cleanall: clean
	rm -rf deps
	rm -rf ab.c ap_release.h ab.1
