STATICS = $(shell find static -type f | xargs echo)
COMPONENTS = $(shell find components -type f -name \*.sql | xargs echo)

app.sql: $(COMPONENTS)
	cat $(COMPONENTS) > $@


components/01-static.sql: ${STATICS}
	python3 generate_static.py > $@
