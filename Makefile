.PHONY: all

SUBDIRS = resume

all:
	$(foreach subdir, ${SUBDIRS}, cd $(subdir) && make)

clean:
	$(foreach subdir, ${SUBDIRS}, cd $(subdir) && make clean)
