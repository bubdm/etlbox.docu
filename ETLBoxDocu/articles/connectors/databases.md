# Database integration

## Supported databases

These database are currently supported with ETLBox:

- Sql Server (Native, Odbc, OleDb)
- Postgres (Native, Odbc)
- SQLite (Native, Odbc)
- Oracle (Native, Odbc)
- MySql (Native, Odbc)
- Db2 (Native)
- MariaDb (Native, Odbc)
- Microsoft Access (only Odbc)

There is a limited support for other databases as well - you can use the generic Odbc or OleDb driver to access these databases. 

## Connection Manager

While you will always have access to the DbSource and DbDestination when you added ETLBox as package reference, you can't do much with them as you will need the right connection manager to connect with your database.  For Sql Server you would need the SqlConnectionManager, and for MySql the MySqlConnectionManager. 

Here the example code for creating a connection manager for Postgres:

```C#
PostgresConnectionManager connectionManager = new PostgresConnectionManager("Server=10.37.128.2;Database=ETLBox_DataFlow;User Id=postgres;Password=etlboxpassword;");
```

Creation of a connection manager for SQLite:

```C#
SQLiteConnectionManager connectionManager = new SQLiteConnectionManager("Data Source=.\\db\\SQLiteControlFlow.db;Version=3;");
```

There is also an OracleConnectionManager, MariaDbConnectionManager and an AccessOdbcConnectionManager.

## DbSource

The DbSource give you access to any database table or with your database. Or you can directly pass an sql statement that is used as source.
The use of the DbSource is very straight forward. You simple pass a connection manager (the right one for your database) and a table name

```C#
public class MyRow
{
    public int Id { get; set; }
    public string Value { get; set; }
}
SqlConnectionManager connMan = new SqlConnectionManager("Data Source=.;Integrated Security=SSPI;Initial Catalog=ETLBox;");
DbSource<MyRow> source = new DbSource<MyRow>(connMan, "SourceTable");
```

If you table that you connect with has the columns Id and/or Value, the data will be read from this columns and passed into the connected component. 

### Sql Code 

For the `DbSource`, you can also specify some Sql code to retrieve your data:

```C#
DbSource<MyRow> source = new DbSource<MyRow>() {
    ConnectionManager = connMan, 
    Sql = "SELECT Id, Value FROM SourceTable"
};
```

### Using dynamic object

The default implementation of DbSource will use an ExpandoObject. This dynamic object will then properties with the same names as the columns in your source.

```C#
DbSource source = new DbSource(connMan, "SourceTable");
```

No object is need when using this. Make sure that all other components also either use the default implementation, or alternatively you cast the ExpandoObject into an object or array of your choice. This can be done e.g. with a RowTransformation

### Using string arrays

Also you can use the DbSource to read your data directly into an array. This could be a string array. The order of the columns of your table or you sql code is then equals the order in your array. Also, you don't need any other object definition then. 

```C#
DbSource<string[]> source = new DbSource<string[]>(connMan, "SourceTable");
```


## DbDestination 

The DbDestination will write that data from your flow into the a table. Like the DbSource, you need to pass a connection manager and the destination table name. For any property in your object, the data will be written into the table if the column names match with the property name. 

```C#
public class MyRow
{
    public int Id { get; set; }
    public string Value { get; set; }
}
SqlConnectionManager connMan = new SqlConnectionManager("Data Source=.;Integrated Security=SSPI;Initial Catalog=ETLBox;");
DbDestination<MyRow> dest = new DbDestination<MyRow>(connMan, "DestinationTable");
```

If your table has the columns Id and/or Value, the data of your flow will be written into this columns.

### Using dynamic objects

Of course you can also use the default implementation of the DbDestination to write data into a table. 

```C#
SqlConnectionManager connMan = new SqlConnectionManager("Data Source=.;Integrated Security=SSPI;Initial Catalog=ETLBox;");
DbDestination dest = new DbDestination(connMan, "DestinationTable");
```

Like with an object, the properties of the ExpandoObject are used to map the values to the right columns. Only if the ExpandoObject object has a property with the same name as the column in the destination table, data is written into this column. 
Unfortunately, the Column mapping attributes are not working here. 

### Using arrays

You can also use the DbDestination with array.

```C#
SqlConnectionManager connMan = new SqlConnectionManager("Data Source=.;Integrated Security=SSPI;Initial Catalog=ETLBox;");
DbDestination<string[]> dest = new DbDestination<string[]>(connMan, "DestinationTable");
```

The data is written into the columns in the same order as they are stored in the array. E.g., if your string array has three values, these values are stored into the first, second and third column of your destination table. If your destination table has more columns, these will be ignored. Identity columns (or auto increment / serial values) are ignored. 

### Batch Size

By default, the DbDestination will create batches of data that then are inserted in whole into the database. This is faster than creating a single insert for each incoming row. So the DbDestination is a little bit different from the other destinations: It will always wait until it has received the full amount of rows needed for a batch, and then do the insert. The default batch size is 1000. 
You can play around with the batch size to gain higher performance. 1000 rows per batch is a solid value for most operations.
If you encounter the issue that inserted the data into the destinations takes to long, try to reduce the batch size significantly. 

#### Odbc and OleDb connections

If you leave the default value for batch size set, it will be changed to 100 rows for Odbc and OleDb connections. As the connection here is much slower than "native" connections, and bulk inserts need to be translated into "INSERT INTO" statements, 100 rows per batch leads to a much better performance than 1000 rows. 


## Column Mapping 

Of course the properties in the object and the columns can differ - ETLBox will only load columns from a source where it can find the right property. If the data type is different,
ETLBox will try to automatically convert the data. If the names are different, you can use the attribute ColumnMap to define the matching columns name for a property. 
In our example, we could replace the property Id with a property Key - in order to still read data from the Id column, we add the ColumnMap attribute. Also, if we change
the data type to string, ETLBox will automatically convert the integer values into a string. 

```C#
[ColumnMap("Id")]
public string Key { get;set; }
```

### Column Mapping with ExpandoObject

If you use the default implementation of DbSource/DbDestination, then the ExpanoObject will be used internally. This dynamic object doesn't allow you to set attributes as decorators for property. Instead you can pass the attributes manually to the `ColumnMapping` property.

```C#
var source = new DbSource(connectionManager, "TableName");
source.ColumnMapping = new[]
{
    new ColumnMap() {DbColumnName = "Col1", PropertyName = "Id"},
    new ColumnMap() {DbColumnName = "Col2", PropertyName = "Text"}
};
```

## Default ConnectionManager

Every component or task related to a database operation needs to have a connection managers set in order
to connect to the right database. Sometimes it can be cumbersome to pass the same connection manager over and over
again. To avoid this, there is a static `ControlFlow` class that contains the property `DefaultDbConnection`.
If you define a connection manager here, this will always be used as a fallback value if no other connection manager property was defined.

```
ControlFlow.DefaultDbConnection = new SqlConnectionManager("Data Source=.;Integrated Security=SSPI;Initial Catalog=ETLBox;");
//Now you can just create a DbSource like this
var source = new DbSource("SourceTable");
```

### Connection String wrapper

When you create a new connection manager, you have the choice to either pass the connection string directly or you
 create an adequate ConnectionString object from the connection string before you pass it to the connection manager.
 The ConnectionString object does exist for every database type (e.g. for MySql it is `MySqlConnectionString`). The ConnectionString
 wraps the raw database connection string into the appropriate ConnectionStringBuilder object and also offers some more
 functionalities, e.g. like getting a connection string for the database storing system information. 

```C#
SqlConnectionString etlboxConnString = new SqlConnectionString("Data Source=.;Integrated Security=SSPI;Initial Catalog=ETLBox;");
SqlConnectionString masterConnString = etlboxConnString.GetMasterConnection();

//masterConnString is equal to "Data Source=.;Integrated Security=SSPI;"
SqlConnectionManager conectionToMaster = new SqlConnectionManager(masterConnString); 
```

#### ODBC Connections

The `DbSource` and `DbDestination` also works with ODBC connection. Currently ODBC connections with Sql Server and Access are supported. 
You will still use the underlying ADO.NET, but it allows you to connect to SQL Server or Access databases via ODBC. 

Here is how you can connect via ODBC:
  
```C#
DbSource source = DbSource (
    new SqlODBCConnectionManager("Driver={SQL Server};Server=.;Database=ETLBox_ControlFlow;Trusted_Connection=Yes"),
    "SourceTable"
);
```

*Warning*: ODBC does not support bulk inserts like in "native" connections.
The `DbDestination` will do a bulk insert by creating a sql insert statement that
has multiple values: INSERT INTO (..) VALUES (..),(..),(..)

#### Access DB Connections

The ODBC connection to Microsoft Access databases have more restrictions. ETLBox is based .NET Core and will run in your application as dependency.
It now depends if you compile your application with 32bit or 64bit (some version of .NET Core only support 64bit). You will need
the right Microsoft Access driver installed - either 32bit or 64bit. You can only install the 32bit driver
if you have a 32bit Access installed, and vice versa. Also, make sure to set up the correct ODBC connection (again, there is 
64bit ODBC connection manager tool in windows and a 32bit). 

The corresponding 64bit ODBC driver for Access can be download 
Microsoft: [Microsoft Access Database Engine 2010 Redistributable](https://www.microsoft.com/en-us/download/details.aspx?id=13255)

To create a connection to an Access Database, use the `AccessOdbcConnectionManager` and an `OdbcConnectionString`.

```C#
DbDestination dest = DbDestination (
    new AccessOdbcConnectionManager(new OdbcConnectionString("Driver={Microsoft Access Driver (*.mdb, *.accdb)}DBQ=C:\DB\Test.mdb")),
    "DestinationTable"
);
```
*Warning*: The `DbDestination` will do a bulk insert by creating a sql statement using a sql query that Access understands. The number of rows per batch is 
very limited - if it too high, you will the error message 'Query to complex'. Try to reduce the batch size to solve this.

*Note*: Please note that the AccessOdbcConnectionManager will create a "temporary" dummy table containing one record in your database when doing the bulk insert. After completion it will delete the table again. 
This is necessary to simulate a bulk insert with Access-like Sql. 

### Generic Odbc and OleDb conenctions

As ETLBox has some database specific code in different components, you normally would choose an Odbc or OleDb connector that fits to your database. 

But if your database is not supported yet, you can use the generic Odbc or OleDb connection manager to connection with *any* database. 
Make sure you reference the Odbc or OleDb connector package. 

- [OleDb connector package for ETLBox](https://www.nuget.org/packages/ETLBox.OleDb)
- [Odbc connector package for ETLBox](https://www.nuget.org/packages/ETLBox.Odbc)

Unfortunately, this connector will have some limitations.

- if you use DbDestination or DbSource with this connector, you would need to pass a TableDefinition object. This object basically holds the table name and column names, because they can't be automatically extracted from the database.
- some ControlFlow components won't work (e.g. IfTableExistsTask). But SqlTask will work with the generic connection manager
- if you use special characters in your table or columns names, you need to set the quotation begin / quotation end properties QB & QE that fit to your database (e.g. "[" and "]" for Sql Server or "`" for MySql)

#### Example with SqlServer OldDb

E.g. you can use the generic OleDb connection manager to connect with Sql Server via OleDb

You will need an OleDb connection string,. 
```C#
var connString = @"Provider=MSOLEDBSQL;Server=10.211.55.2;Database=ETLBox_DataFlow;UID=sa;PWD=YourStrong@Passw0rd;"
OleDbConnectionManager conn = new OleDbConnectionManager(connString);
conn.QB = "["; conn.QE = "["; //not always needed, only for special characters
SqlTask.ExecuteNonQuery(conn, , "INSERT INTO...");
```

You can also use this connection manager with the DbSource or the DbDestination component. But please note that this will only work if you pass the TableDefinition manually, like this:

```C#
var cols = new List<TableColumn>() {
                new TableColumn("Col1", "INT", allowNulls: false),
                new TableColumn("Col2", "VARCHAR(100)", allowNulls: true)
};
_sourcedef = new TableDefinition("TestTable", cols);
DbSource<MySimpleRow> source = new DbSource<MySimpleRow>(conn)
 {
     SourceTableDefinition = _sourcedef
};
```

Same for DbDestination - the property name is `DestinationTableDefinition` there. 

### Connection Pooling

The implementation of all connection managers is based on Microsoft ADO.NET and makes use of the underlying 
connection pooling. [Please see here for more details of connection pooling.](https://docs.microsoft.com/en-us/dotnet/framework/data/adonet/sql-server-connection-pooling)
This means that this actually can increase your performance, and in most scenarios you never have more 
connections open that you actually need for your application.

You don't need to explicitly open a connection. ETLBox will call the `Open()` method on a connection manager whenever
needed - where it relies on the underlying ADO.NET connection pooling that either creates a new connection 
or re-uses an existing one. Whenever the work of a component or task is done, the connection manager will return the connection back to 
the pool so that it can be reused by other components or tasks when needed.

Please note that the connection pooling only works for the same connection strings. For every connection string that differs there
is going to be a separate pool 

This behavior - returning connections back to the pool when the work is done - does work very well in a scenario 
with concurrent tasks. There may be a use-case where you don't won't to query your database in parallel and you 
want to leave the connection open, avoiding the pooling. [For this scenario you can use the `LeaveOpen` property
on the connection managers.](https://github.com/etlbox/etlbox/issues/39)


### Table Definitions

If you pass a table name to a `DBsource` or `DbDestination` or a Sql statement to a `DbSource`, the meta data
of the table is automatically derived from that table or sql statement by ETLBox. For table or views this is done via a Sql statement that queries
system information, and for the Sql statement this is done via parsing the statement. 
If you don't want ETLBox to read this information, or if you want to provide your own meta information, 
you can pass a `TableDefinition` instead.

This could look like this:

```
var TableDefinition = new TableDefinition("tableName"
    , new List<TableColumn>() {
    new TableColumn("Id", "BIGINT", allowNulls:false,  isPrimaryKey: true, isIdentity:true)),
    new TableColumn("OtherCol", "NVARCHAR(100)", allowNulls: true)
});

var DbSource<type> = new DbSource<type>() {  
  SourceTableDefinition = TableDefinition
}
```

ETLBox will use this meta data instead to get the right column names. 