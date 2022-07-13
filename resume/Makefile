.PHONY: all

CC = xelatex
OUTPUT_DIR = .
RESUME_DIR = .

all: $(foreach x, tinhkyaw-resume, $x.aux $x.pdf)

tinhkyaw-resume.aux:
	for i in 1 2; do \
		$(CC) -output-directory=$(OUTPUT_DIR) \
		${RESUME_DIR}/tinhkyaw-resume.tex; \
	done

tinhkyaw-resume.pdf:
	$(CC) -output-directory=$(OUTPUT_DIR) ${RESUME_DIR}/tinhkyaw-resume.tex

clean:
	rm -rf $(OUTPUT_DIR)/*.pdf
