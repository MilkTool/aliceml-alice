##
## Alice build and installation (dumb)
##

PWD := $(shell pwd)

GLOBAL_PREFIX = /opt/stockhausen-devel
PREFIX = $(PWD)/install
TIMEDIR = $(PWD)/time

OPTS1= # '--dump-phases' # --dump-abstraction-result' # --dump-intermediate'
OPTS2= # '--dump-phases'
OPTS3= # '--dump-phases' # --dump-intermediate'

PLATFORM = $(shell bootstrap/platform.sh smlnj)
ifeq ($(PLATFORM:%win32=win32), win32)
    WINDOWS = 1
else
    WINDOWS = 0
endif

.PHONY: clean clean-common clean-mozart clean-seam \
	install install-prelude install-common install-global install-mozart install-seam \
	bootstrap-smlnj bootstrap-mozart bootstrap-seam build-seam \
	libs-mozart libs-seam \
	docs

##
## Do it!
##
install: install-mozart
	@echo -------------------------------------------------------------------------------
	@echo Installation of Alice for $(PLATFORM) complete.
	@echo Time for build 1:
	@cat $(TIMEDIR)1
	@echo Time for build 3:
	@cat $(TIMEDIR)3
	
install-common: install-prelude bootstrap-smlnj docs

install-prelude:
	@echo Installing Alice to $(PREFIX) for $(PLATFORM)...
	@echo -------------------------------------------------------------------------------
	
##
## Sync the global installation with local one
##
install-global: install
	(cd $(PREFIX) && tar -cf - *) | \
	(cd $(GLOBAL_PREFIX) && tar -xvf -)

##
## Build the bootstrap compiler on SML/NJ
##
bootstrap-smlnj:
	rm -f bootstrap/alicec-*.$(PLATFORM) #bootstrap/alicedep.$(PLATFORM)
	(cd bootstrap && make all) || exit 1

##
## Documentation
##
docs:
	(cd doc/manual && make PREFIX=$(PREFIX)/doc) || exit 1

##
## Clean-up
##
clean: clean-mozart

clean-mozart: clean-common
	rm -f bootstrap/alicec-mozart.$(PLATFORM) #bootstrap/alicedep.$(PLATFORM)
	(cd vm-mozart && make distclean) || exit 1
	(cd lib/inspector && make distclean) || exit 1
	(cd lib/constraints && make distclean) || exit 1
	(cd lib/distribution && make distclean) || exit 1
	(cd lib/gtk && ([ -f Makefile ] && make distclean || exit 0)) || exit 1

clean-seam: clean-common
	rm -f bootstrap/alicec-seam.$(PLATFORM) #bootstrap/alicedep.$(PLATFORM)
	(cd vm-seam && make clean WINDOWS=$(WINDOWS)) || exit
	(cd vm-seam && make -f Makefile.bootstrap distclean) || exit 1
	(cd lib/distribution && make TARGET=seam distclean) || exit 1

clean-common:
	(cd bootstrap && make clean) || exit 1
	rm -f time[1-3]

veryclean: clean
	(cd bootstrap && make veryclean) || exit 1
	rm -rf */CM */*/CM */*/*/CM


################################################################################
## Mozart-specific stuff
################################################################################

##
## Install Alice on Mozart
##
install-mozart: install-common bootstrap-mozart libs-mozart

bootstrap-mozart:
	unset ALICE_HOME ;\
	(cd vm-mozart && make depend) || exit 1 ;\
	(cd vm-mozart && /usr/bin/time -po $(TIMEDIR)1 \
		make ALICEC_EXTRA_OPTS="$(OPTS1)" build1-install) || exit 1 ;\
	(cd vm-mozart && \
		make ALICEC_EXTRA_OPTS="$(OPTS2)" build2-all) || exit 1 ;\
	(cd vm-mozart && /usr/bin/time -po $(TIMEDIR)3 \
		make ALICEC_EXTRA_OPTS="$(OPTS3)" build3-install) || exit 1 ;\
	(cd vm-mozart && make PREFIX=$(PREFIX) install) || exit 1

libs-mozart:
	unset ALICE_HOME ;\
	export PATH=$(PREFIX)/bin:$(PATH) ;\
	(cd lib/inspector && make depend) || exit 1 ;\
	(cd lib/inspector && make all PREFIX=$(PREFIX) install) || exit 1 ;\
	(cd lib/constraints && make depend) || exit 1 ;\
	(cd lib/constraints && make all PREFIX=$(PREFIX) install) || exit 1 ;\
	(cd lib/distribution && make depend) || exit 1 ;\
	(cd lib/distribution && make all PREFIX=$(PREFIX) install) || exit 1 ;\
	(cd lib/gtk && autoconf && \
	 ./configure --with-gtk-canvas-dir=/opt/gtk-canvas) || exit 1 ;\
	(cd lib/gtk && make all PREFIX=$(PREFIX) install) || exit 1
	#(cd lib/gtk && make depend) || exit 1


################################################################################
## Seam-specific stuff
################################################################################

##
## Install Alice on Seam
##
install-seam: install-common bootstrap-seam libs-seam

bootstrap-seam: build-seam
	unset ALICE_HOME ;\
	export TIMEDIR ;\
	(cd vm-seam && make -f Makefile.bootstrap depend) || exit 1 ;\
	(cd vm-seam && /usr/bin/time -po $(TIMEDIR)1 \
		make -f Makefile.bootstrap ALICEC_EXTRA_OPTS="$(OPTS1)" \
			build1-install) || exit 1 ;\
	(cd vm-seam && make -f Makefile.bootstrap ALICEC_EXTRA_OPTS="$(OPTS2)" \
			build2-install) || exit 1 ;\
	(cd vm-seam && /usr/bin/time -po $(TIMEDIR)3 \
		make -f Makefile.bootstrap ALICEC_EXTRA_OPTS="$(OPTS3)" \
			build3-install) || exit 1 ;\
	(cd vm-seam && make -f Makefile.bootstrap install) || exit 1

libs-seam:
	unset ALICE_HOME ;\
	export PATH=$(PREFIX)/bin:$(PATH) ;\
	(cd lib/distribution && make TARGET=seam depend) || exit 1 ;\
	(cd lib/distribution &&
	 make TARGET=seam all PREFIX=$(PREFIX)/share/alice install) || exit 1

##
## Build Seam
##
build-seam:
	(cd vm-seam && \
	 make -f Makefile.cvs && \
	 ./configure --prefix=$(PREFIX) \
	  	     --with-lightning="$(PWD)/../../seam-support/install" && \
	 make install) || exit 1
