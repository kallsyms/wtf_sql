STATICS = $(shell find static -type f | xargs echo)
COMPONENTS = components/00-base.sql components/01-static.sql components/02-routes.sql

app.sql: $(COMPONENTS)
	cat $(COMPONENTS) > $@


components/01-static.sql: ${STATICS}
	python3 generate_static.py > $@
