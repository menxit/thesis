build:
	make epub
	make pdf

epub:
	mkdir -p out
	./bin/build-x.sh out/thesis.epub

pdf:
	mkdir -p out
	./bin/build-pdf.sh out/thesis.pdf