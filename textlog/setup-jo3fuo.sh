#!/bin/sh
rm -i jo3fuo-now.txt
cp jo3fuo-template.txt jo3fuo-now.txt
chmod u+w jo3fuo-now.txt
rm -i jo3fuo-now.txt.bak
./bdxtextlog-input.pl -f jo3fuo-now.txt
