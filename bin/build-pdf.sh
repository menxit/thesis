pandoc 	--filter pandoc-citeproc \
	--template=template/template.latex \
	README.md \
	-o $1