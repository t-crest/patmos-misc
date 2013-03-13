all: manual.pdf

.PHONY: clean distclean

manual.pdf: *.tex content/*.tex data/*
	pdflatex -interaction=nonstopmode manual
	bibtex manual
	pdflatex -interaction=nonstopmode manual
	pdflatex -interaction=nonstopmode manual

clean:
	rm -f *.aux *.log *.out *.toc *.bbl *.blg content/*.aux 

distclean: clean
	rm -f manual.pdf
