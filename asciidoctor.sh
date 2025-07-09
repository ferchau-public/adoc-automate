#!/bin/sh

INPUTFILE="README"

if [ ! -d ".asciidoctor/reveal.js" ]; then
	git clone -b 5.2.0 --depth 1 https://github.com/hakimel/reveal.js.git .asciidoctor/reveal.js
fi

# Generate PDFs

docker container run \
     --interactive --rm \
     --user "$(id -u):$(id -g)" \
     --volume "$(pwd):/opt/prj/" \
     adoc-automate \
         asciidoctor-pdf \
             --backend pdf \
             --failure-level=WARN \
             --verbose --timings \
             -a pdf-fontsdir=.asciidoctor/fonts/ \
             -a pdf-theme=.asciidoctor/themes/ferchau/pdf-theme.yml \
             "${INPUTFILE}.adoc"

# Generate HTML Slides

docker container run \
     --interactive --rm \
     --user "$(id -u):$(id -g)" \
     --volume "$(pwd):/opt/prj/" \
     adoc-automate \
         asciidoctor-revealjs \
             --failure-level=WARN \
             --verbose --timings \
             "${INPUTFILE}.adoc"

# Generate PDF-Slides from HTML

docker container run \
     --interactive --rm \
     --user "$(id -u):$(id -g)" \
     --volume "$(pwd):/opt/prj/" \
     adoc-automate \
         /bin/bash -c "\
         python reveal2pdf.py \
         file:///opt/prj/${INPUTFILE}.html \
         ${INPUTFILE}.slides.pdf"
