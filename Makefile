.PHONY: all

SUBDIRS = resume

all:
	(cd ${SUBDIRS} && make)

clean:
	(cd ${SUBDIRS} && make clean)
