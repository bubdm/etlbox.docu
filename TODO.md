# Open bugs / tasks / features

### Control Flow
- CreateTableTask.CreateOrAlter() and Migrate(): add functionality to alter a table if empty, or Migrate a table if not empty
 () MigrateTables - will compare two tables via their defintion, and then alter the table if empty or copy the existing data into the new table)
- CopyTableDefinitionTask: uses TableDefinition to retrieve the current table definiton and the creates a new table. 
Very good for testing purposes.(Be careful, the PK name must be ignored or changed for some dbs)

### Connection Manager / Performance
- ModifyDbSettings: Now the Connection Manager have a PrepareBulkInsert/CleanUpBulkInsert method. There are missing tests that check that make use of the Modify-Db settings and verify improved performance. DbDestination modifies these server side settings only once and at then end end of all batches.
- SMOConnectionManager: Check if SMOConnectionManager can be reinstalled again
- Improved Odbc support: This is only relevant for Unknown Odbc (or OleDb) source. For better Odbc supportl also  look at DbSchemaReader(martinjw) in github.
Currently, if not table definition is given, the current implementation of TableDefintion.FromTable name throws an exception that the table does not exists (though it does). For known Odbc connection (like Sql Server), the sql is known, but for the "default" odbc connection there can't be a sql to get the table definition. But this could be done using the Ado.NET schema objects. 
It would be good if the connection manager would return the code how to find if a table exists. Then the normal conneciton managers would run some sql code, and the Odbc could use ADO.NET to retrieve if the table exists and to get the table definition (independent from the database).

### Connectors 
- Limit: All sources (DbSource, CsvSource, etc. )  always read all the data from the source. For development purposes it would be benefical if only the first X rows are read from the source. A property `public int Limit` could be introduced, so that only the first X rows are read for a DBSource/CSVSource/JsonSource/. This is already implementented with the DbSource. For other source like Csv/Json, there should be a counter on the lines within the stream reader...

### Transformations
- LinkErrorTo Performance: Blocking/batch transformation can have a link error to, but this can produce a lot of output. Write some performacne tests for it- perhaps write out the error message in batches as well? At least this makes sense for the BlockTransformation, because data can get quite big here

## Network class
- The Network class can execute all sources and wait for all destination (see existing branch where I did the first tests)
- if dataflow component is connected to two successor, but without using predicates, data is only send to the first successor. This is confusing: If there are links to more than one successor, and no predicate nor Multicast is in between, an exception or log output should be produced (probably part of a "Network" class)
- network class should check for circles
- network class should check if all transformations have output
- network class can check (if all objects are passed) if everything is connected
- netwrok should check if two or more transformation are linked without predicates
- If not everything is connected to an destination when using predicates, it can be that the dataflow never finishes. Write some tests. See Github project DataflowEx for implementation how to create a predicate that always discards records not transferred.


# MySql Connector
- The links below don't help, internally the solution does use the "LOAD INFILE" statement with the restriction that a user needs to create a csv file on the server...
- See last answer here: [Most efficient way to insert Rows into MySQL Database - Stack Overflow:](https://stackoverflow.com/questions/25323560/most-efficient-way-to-insert-rows-into-mysql-database)
- [mysql-net/MySqlConnector: Async MySQL Connector for .NET and .NET Core](https://github.com/mysql-net/MySqlConnector)

# ColumnRename: 
- Add an action that allows to have a particular renaming action invoked for every row - this can be additionally to the existing renaming via ColumnMapping
- the current logic does lock faulted. What about columsn which aren't renamed? Do they stay (which should be the desired behavior) or are they removed? What about the RemoveColumn property? 

# Ideas

- Release notes page?
- Roadmap page? 
- Excel IngoreBlankRows without Range - infinite loop?
- RowTransformation: Add Parallelization
- make list properties to ICollection or IEnumerable (e.g. MemorySource/Dest or TableDefinition)
- Redo logging - this is currently messy
- Add parquet source/destination
- Add neo4j sourcd/destination
- add db2 support
- add more databases: Teradata, Redshift, Ingres, ...?


# Inbox

- Make almost all classes (except POCO etc.) sealed - this would need a better docu creation. Currently, every data flow transformation e.g. RowTransformation<TInput, TOutput> has a derived class RowTransformatiomo<ExpandoObject, ExpandoObject>. To seal these properly, the current kRowTransformation<TInput, TOutput> would need to be internal and derived classes public


-Oracle: table definition sql takes too long. also, computed columns are not properly read from table definition.(test needs to be extended)
- new idea: ForEachTableInDatabaseTask, that gets a lamda expression an interates through each database table... this is basically a foreach through the output of sys.tables in SqlServer... 
- Bulk Insert: Convert "yyyyMMdd" string to DateTime automatically (add this to the IDataReader implementation): the idea would be to add for every connection manager some kind of "Convert" property: It contains the incoming data type of the columns (e.g. DATETIME), and returns a parsed object (something like this). So the user could create it own conversion function! Don't forget to clone this property also automatically (perhaps something like a base.clone() call). Also, some tests are needed to check if this behavior works with index columns as well
- New Transfomration: NullFilter - idea is to filter out null rows in a a flow, e.g. generated by a RowTransformation
- HashHelper: move the code from the HashHelper class into testhelper, and remove the hash generation from logging (does not really make sense here)
- Lookup transformation now has a "IgnoreDataTypes" options. This works well when comparing (matching) data. But not when writing data into the target. It uses the TrySetValue to set the value in the input, but this does not work if data types do not match when. Only same data types can be written. This could be changed: TrySetValue could do the same thing as DbSource/DbDestination: it could always try to cast the data type into the proper format. This could be part of refactoring/unifying how to write data into properties
- Oracle now offers the OracleBulkCopy class in it's nuget package. Usage is similar to SqlServer or Db2. 
This could be implemented, but the whole IDataReader / TableData class need to be refactored, as this whoel thing does not work if values for identity columns are passed (values & columns need to be removed)
- Db2 also has a SqlBulkCopy like class. This can be added if the IDataReader/TableData class is refactored - the identity columns must be removed (all columns & values), otherwise this won't work.
- New issue: A multicast with two Database destiantions sometimes hangs forever if one of the destinations fails right from the start (see test case DbDestinationTransactionTests.OneTransactionAndParallelWriting) - create a test that reproduces this and check if the can be solved (e.g. by always canceling all components in the whole flow? This could be done with the Network class? The network class could monitor everything and then cancel things if something looks odd... 
- Contact formular: When submitting, everything is blank... Eventually the iframe needs to be resized?

