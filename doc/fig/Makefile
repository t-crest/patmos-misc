PDF=framework.pdf

all: $(PDF)

%.pdf: %.pgf tikz2pdf.tex
	pdflatex --jobname=$* tikz2pdf.tex && rm -f *.aux *.log

%.jpg: %.pdf
	pdftoppm $< | ppmtojpeg > $@

clean:
	rm -f $(PDF) *.aux *.log
	rm -f *.jpg
