pandoc 	--filter pandoc-citeproc \
	README.md \
	$(echo $(ls chapters | awk '{print "chapters/"$0}')) \
	-o $1