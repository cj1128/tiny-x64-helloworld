SHELL = /bin/bash

all := step0,step1,step2,step3,step4,step5,step6,step7,final

build:
	@for dir in {$(all)}; do \
	(cd $$dir && make build); \
	done
.PHONY: build

clean:
	@for dir in {$(all)}; do \
	rm $$dir/hello.out; \
	done
.PHONY: clean

list:
	@ls -U -l {$(all)}/hello.out
.PHONY: list

