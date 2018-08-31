pandoc 	--filter pandoc-citeproc \
	--template=template/template.latex \
	0-OPTIONS.org \
	1-ACKNOWLEDGEMENT.org \
	2-INTRODUCTION.org \
	README.org \
	4-CONCLUSION.org \
	-o $1