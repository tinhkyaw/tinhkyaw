.PHONY: all

CC = xelatex
OUTPUT_DIR = .
RESUME_DIR = resume/tex
RESUME_FILES = $(shell find $(RESUME_DIR) -name '*.tex')

all: $(foreach x, tinhkyaw-resume, $x.pdf)

tinhkyaw-resume.pdf: ${RESUME_DIR}/tinhkyaw-resume.tex $(RESUME_FILES)
	$(CC) -output-directory=$(OUTPUT_DIR) $<

clean:
	rm -rf $(OUTPUT_DIR)/*.pdf
