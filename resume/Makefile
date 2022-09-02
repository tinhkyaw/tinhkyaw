.PHONY: all

CC = xelatex
OUTPUT_DIR = .
RESUME_DIR = .

all: $(foreach x, tinhkyaw-resume, $x.aux $x.pdf $x-1.png $x-2.png)

tinhkyaw-resume.aux:
	for i in 1 2; do \
		$(CC) -output-directory=$(OUTPUT_DIR) \
		${RESUME_DIR}/tinhkyaw-resume.tex; \
	done

tinhkyaw-resume.pdf:
	$(CC) -output-directory=$(OUTPUT_DIR) ${RESUME_DIR}/tinhkyaw-resume.tex

tinhkyaw-resume-1.png tinhkyaw-resume-2.png:
	pdftoppm -png tinhkyaw-resume.pdf tinhkyaw-resume

clean:
	rm -rf $(OUTPUT_DIR)/*.pdf ${OUTPUT_DIR}/*.png
