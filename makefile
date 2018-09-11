STATICS = $(shell find static -type f | xargs echo)
GENERATED = components/01-static.sql components/02-templates.sql
COMPONENTS = $(shell find components -type f -name \*.sql | sort -)

all: $(GENERATED) app.sql

app.sql: $(COMPONENTS)
	cat $(COMPONENTS) > $@

components/01-static.sql: ${STATICS}
	python3 generate_static.py > $@

components/02-templates.sql: ${STATICS}
	python3 generate_templates.py > $@

clean:
	rm -f app.sql $(GENERATED)
	touch -t 197010101010.01 $(GENERATED)
