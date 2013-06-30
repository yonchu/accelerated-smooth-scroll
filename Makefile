.PHONY: release

release:
	zip -r accelerated-smooth-scroll.zip ./ -x .git\* doc/tags\* \*.swp Makefile
