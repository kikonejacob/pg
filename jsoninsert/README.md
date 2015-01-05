# JSON insert

A generic function with two parameters:

1. table name
2. JSON hash where keys are table column names, values are new values

The function turns it into an INSERT statement on that table and executes it.

Then it returns updated record.

If any errors, insert is not performed.

## status: not started

It's similar enough to [jsonupdate](https://github.com/sivers/pg/tree/master/jsonupdate) that let's perfect that one first, then do this.

I don't know how to build a multi-column INSERT statement from a JSON hash.

