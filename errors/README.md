# JSON Errors

Remember the ultimate goal of this work is to have a dumb webserver make a REST API by calling functions that always start with **SELECT mime, JS FROM**, like this:

```
SELECT mime, js FROM get_person(123);
SELECT mime, js FROM update_person(123, '{"name":"Dude"}');
SELECT mime, js FROM client_delete_project(7, 95);
```

The webserver knows it will **always** get back a MIME type and JSON hash, so it can just pass those directly into its HTTP response.  No special intelligence needed by the webserver.

So instead of PostgreSQL raising exceptions, I want to **catch all exceptions**, and return [application/api-problem+json](https://tools.ietf.org/html/draft-nottingham-http-problem-06), [like this](https://www.mnot.net/blog/2013/05/15/http_problem).

## status: nascent, many questions

1. Should every function return two named text values, mime and js, or should I define a new type, and return that?
2. How to structure the error-catching & response-forming function?
  * Every function repeats the entire process of catching errors and turning them into JSON responses
  * Only one function performs a query and catches the error, and every other function passes its query through this one, like a proxy
  * One function takes an error and creates the JSON response. Every other function calls it in its EXCEPTION block.
  * Some kind of higher-level “catch all errors and handle them like this” config for PostgreSQL?
3. Return HTTP status code as part of PostgreSQL response? Or leave that up to webserver?  (Perhaps only using 200, 400, 404 instead of the [many](http://en.wikipedia.org/wiki/List_of_HTTP_status_codes), I could scan mime type for “api-problem”=400, “not-found”=404, all else=200.)
4. How to use this same error-reporting function to handle “Not Found” 404 every time a SELECT returns no results?
5. Instead of just the code, how can I get the “condition name” shown in [this chart](http://www.postgresql.org/docs/9.4/static/errcodes-appendix.html)?

