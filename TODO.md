# TODO

## Enhancements
- If not everything is connected to an destination when using predicates, it can be that the dataflow never finishes. Write some tests. See Github project DataflowEx for implementation how to create a predicate that always discards records not transferred.
- Now the Connection Manager have a PrepareBulkInsert/CleanUpBulkInsert method. There are missing tests that check that make use of the Modify-Db settings and verify improved performance. DbDestination modifies these server side settings only once and at then end end of all batches.
- Check if SMOConnectionManager can be reinstalled again
- All sources (DbSource, CsvSource, etc. )  always read all the data from the source. For development purposes it would be benefical if only the first X rows are read from the source. A property `public int Limit` could be introduced, so that only the first X rows are read for a DBSource/CSVSource/JsonSource/. This is quite easy to implement as SqlTask already has the Limit property. For Csv/Json, there should be a counter on the lines within the stream reader...
- CreateTableTask.CreateOrAlter() and Migrate(): add functionality to alter a table if empty, or Migrate a table if not empty
- From PoC: Aggregation supports currently MIN/MAX/COUNT/SUM. What about strings? Something like "FirstValue" or "LastValue" or FirstNonEmpty or LastNonEmpty?
- CopyTableDefinitionTask - uses TableDefinition to retrieve the current table definiton and the creates a new table. 
Very good for testing purposes.
- MigrateTables - will compare two tables via their defintion, and then alter the table if empty or copy the existing data into the new table

### Enhance Merge 
- Old: The current merge does suppor the "UseTruncateMethod" flag. If set to true, the table is truncated before inserted the modified data.
In theory, this will also work for the MergeModes NoDeletions && OnlyUpdates. But then the method `ReinsertTruncatedRecords` should not 
throw an exception - itstead, it should use the InputDataDict to reinsert the records that were truncated (but shouldn't be deleted.)
- New: Remove truncate completely. For large data set, the delete statement will become big. Run the delete statement in bathces
- Add the partial lookup to the merge
- Allow merge to overwrite identity columns (see issue)
- adapt merge to match / compare column attributes (instead of string arrays)

### Enhance Lookup Transformation
- A "partial lookup" could be implemented. In the DbMerge, this could be useful for the DbMerge (in full load with deletions enabled this probably will not,but it should work with other Merge modes NoDeltions, Delta & OnlyUpdates )
- This goes togheter with a cachedrowtransformation, which basically should be able to have a cache and the cache must be filled by a "fillcachefunction"


## Bugs

- PrimaryKeyConstrainName now is part of TableDefinition, but not read from "GetTableDefinitionFrom"
- Check if license file is correctly read from same folder if using a "classic" .NET project (or nunit test project) 
- Double check if the waiting for the buffercompletion/preprocessor completion makes sense, or can be simplified (looks like that always the buffercompletion and predecesssor completion is included, sometimes twice?)
- When an exception is thrown in the AfterBatchWrite of the DbDestination (see DbDestinationExceptionTests), then the thrown exception should bubble up. (E.g. an argumentexception). But instead of this exception the sources are also faulted, and the exception in the sources will bubble up first and rethrown by ETLBox. This should be checked if this can be solved better. 
- If an exception is thrown, this should be written into log output!

### Improved Odbc support:

This is only relevant for Unknown Odbc (or OleDb) source. For better Odbc supportl also  look at DbSchemaReader(martinjw) in github.
Currently, if not table definition is given, the current implementation of TableDefintion.FromTable name throws an exception that the table does not exists (though it does). 
For known Odbc connection (like Sql Server), the sql is known, but for the "default" odbc connection there can't be a sql to get the table definition. But this could be done using the Ado.NET schema objects. 
It would be good if the connection manager would return the code how to find if a table exists. Then the normal conneciton managers would run some sql code, and the Odbc could use ADO.NET to retrieve if the table exists and to get the table definition (independent from the database).

# Ideas

- Release notes page?
- Roadmap page? 
- Excel IngoreBlankRows without Range - infinite loop?
- RowTransformation: Add Parallelization
- Blocking transformation can't have an LinkErrorTo() - throw an exception if this is called
- New transformation: Distinct (as partial blocking) which only let the first row through, but keeps a hash value to identify similar rows
- Match/RetrieveColumn should also be assigable via list properties (attributes can be created with new) - probably together with CachedRowTransformation as well as a solution for patial lookups
- New Destination: CustomBatchDestination
- ColumnRename: Add a "rename column action" which could respace spaces in a columns names or something similar
