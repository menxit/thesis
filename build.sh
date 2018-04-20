pandoc 	--filter pandoc-citeproc \
	--template=template/template.latex \
	README.md \
	$(echo $(ls chapters | awk '{print "chapters/"$0}')) \
	-o thesis.pdf
open thesis.pdf