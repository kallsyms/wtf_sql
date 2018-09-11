STATICS = $(shell find static -type f | xargs echo)
COMPONENTS = $(shell find components -type f -name \*.sql | sort -)

all: components/01-static.sql app.sql

app.sql: $(COMPONENTS)
	cat $(COMPONENTS) > $@

components/01-static.sql: ${STATICS}
	python3 generate_static.py > $@

clean:
	rm -f app.sql components/01-static.sql
