all: logs 

.PHONY: logs run clean

logs:
	./buildlogs.sh

run:
	gource -s 1 --highlight-users --hide-root tcrest.log.all

clean:
	rm -rf *.log 
