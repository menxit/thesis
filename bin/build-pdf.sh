pandoc 	--filter pandoc-citeproc \
	--template=template/template.latex \
	0-OPTIONS.md \
	1-ACKNOWLEDGEMENT.md \
	README.md \
	-o $1