changequote([, ])dnl
define([_NOTFOUND], [
	IF js IS NULL THEN
		mime := 'application/problem+json';
		js := '{"type": "about:blank", "title": "Not Found", "status": 404}';
	END IF;
])dnl
include([schema.sql])dnl
include([functions.sql])dnl
include([fixtures.sql])dnl
include([api.sql])dnl
