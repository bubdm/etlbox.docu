# Lookup data 

## LookupTransformation

If you want to lookup some data from existing tables or other sources, the lookup transformation can help you here. 
It allows you to enrich the incoming rows with data from the lookup source. 

The lookup transformation is similar to a row transformation, with the addition that you can define a lookup source. The lookup source can be any kind of ETLBox source component, e.g. a `DbSource` or `CsvSource`. 
When the first record arrives at the lookup transformation, it will automatically load all data from the lookup source into memory. This data is then available in the lookup transformation. 

### Examples

Let's look at an example. Assuming you have an order record that contains a customer name. 

```C#
public class Order
{    
    public int OrderNumber { get; set; }
    public string CustomerName { get; set; }
    public int? CustomerId { get; set; }
}

var orderSource = new MemorySource<Order>();
orderSource.DataAsList.Add(new Order() { OrderNumber = 815, CustomerName = "John"});
orderSource.DataAsList.Add(new Order() { OrderNumber = 4711, CustomerName = "Jim"});
```

Now we have a customer table in our database that holds two records.

Id|Name
--|---------------
1 |John
2 |Jim

Our goal is to have a transformation that reads the Id from the customer table, based on the customer name. So for John we expect to find the Id 1, and for Jim Id 2. 

#### Manual lookup in RowTransformation

Before we start digging deeper into the lookup, we could use a RowTransformation to achieve the lookup. 
The RowTransformation could look like this:

```C#
 var rowTrans = new RowTransformation<Order>(
    row =>
    {
        int? id = SqlTask.ExecuteScalar<int>(SqlConnection,
            sql: $"SELECT Id FROM CustomerTable WHERE Name='{row.CustomerName}'");
        row.CustomerId = id;
        return row;
    });
```

Beside the fact the we should a parameterized query (which SqlTask also supports), this would work as expected. For every row, the row transformation would call a SELECT on the database and find the corresponding customer id. 
Thought this would work with small amount of data, this can become a bottleneck the more data we trying to send this transformation. Even with a very fast responding database this will always take some milliseconds longer than accessing the data directly in memory. 


#### Loading the data into memory

If we would replace the SELECT statement in the example above with something that directly accesses a list in memory, this would be much faster. This is what the lookup does: it load any kind of ETLBox source (e.g. a `DbSource`, `CsvSource`, `JsonSource`...) into a in-memory list. This is then accessible in the lookup transformation, which is the similar to the row transformation. 

Let's create a DbSource, so that we can pass our customer table to the Lookup. 

```C#
public class Customer
{
    public int Id { get; set; }
    public string Name { get; set; }
}

var lookupSource = new DbSource<Customer>(SqlConnection, "CustomerTable");
```

Now we feed this lookupSource into our LookupTransformation. Then within the lookup transformation function, we can access our in-memory table containing the customer data via the property `LookupData`. In our example, we use a Linq query to read the data from the LookupData list. 

```C#
 var lookup = new LookupTransformation<Order, Customer>();
    lookup.Source = lookupSource;
    lookup.TransformationFunc =
        row =>
        {
            row.CustomerId = lookup.LookupData
                .Where(cust => cust.Name == row.CustomerName)
                .Select(cust => cust.Id)
                .FirstOrDefault();
            return row;
        };
``` 

#### Whole example ocde

Here is the whole example code:

```C#
public class Order
{
    public int OrderNumber { get; set; }
    public string CustomerName { get; set; }
    public int? CustomerId { get; set; }
}

public class Customer
{
    public int Id { get; set; }
    public string Name { get; set; }
}

 public static void Main()
{
    var orderSource = new MemorySource<Order>();
    orderSource.DataAsList.Add(new Order() { OrderNumber = 815, CustomerName = "John" });
    orderSource.DataAsList.Add(new Order() { OrderNumber = 4711, CustomerName = "Jim" });

    var lookupSource = new DbSource<Customer>(SqlConnection, "CustomerTable");

    var lookup = new LookupTransformation<Order, Customer>();
    lookup.Source = lookupSource;
    lookup.TransformationFunc =
        row =>
        {
            row.CustomerId = lookup.LookupData
                .Where(cust => cust.Name == row.CustomerName)
                .Select(cust => cust.Id)
                .FirstOrDefault();
            return row;
        };

    var dest = new MemoryDestination<Order>();

    orderSource.LinkTo(lookup).LinkTo(dest);
    orderSource.Execute();
    dest.Wait();

    foreach (var row in dest.Data)
        Console.WriteLine($"Order:{row.OrderNumber} Name:{row.CustomerName} Id:{row.CustomerId}");

    //Output
    //Order:815 Name:John Id:1 
    //Order:4711 Name:Jim Id:2
}
```

#### Using own IList object

Alternatively, if you want to use your own list object where the data is stored, you can overwrite the property `LookupData` with your own object - everything that implements IList can be passed here. 

### Using Attributes

Of course defining your own lookup function can be cumbersome sometimes. The lookup also defines a default lookup implementation, which is based on attributes in your objects. This allows you to control the data lookup without the need to write your own data retrieval function. 

The attributes needed to control the lookup are `MatchColumn` and `RetrieveColumn`. The MatchColumn defines the property name in the target object that needs to match. Only if the records matches (and also only for the first one) it will continue to retrieve the value using the `RetrieveColumn`. The RetrieveColumn tells the lookup the property name of the lookup type class from which the data is retrieved. 

So modifying our example above, it would look like this:

```C#
public class Order
{
    public int OrderNumber { get; set; }
    public string CustomerName { get; set; }
    public int? CustomerId { get; set; }
}

 public class CustomerWithAttr
{
    [RetrieveColumn(nameof(Order.CustomerId))]
    public int Id { get; set; }
    [MatchColumn(nameof(Order.CustomerName))]
    public string Name { get; set; }
}

public static void Main()
{
    var orderSource = new MemorySource<Order>();
    orderSource.DataAsList.Add(new Order() { OrderNumber = 815, CustomerName = "John" });
    orderSource.DataAsList.Add(new Order() { OrderNumber = 4711, CustomerName = "Jim" });

    var lookupSource = new DbSource<CustomerWithAttr>(SqlConnection, "CustomerTable");

    var lookup = new LookupTransformation<Order, CustomerWithAttr>();
    lookup.Source = lookupSource;          

    var dest = new MemoryDestination<Order>();

    orderSource.LinkTo(lookup).LinkTo(dest);
    orderSource.Execute();
    dest.Wait();

    foreach (var row in dest.Data)
        Console.WriteLine($"Order:{row.OrderNumber} Name:{row.CustomerName} Id:{row.CustomerId}");

    //Output
    //Order:815 Name:John Id:1 
    //Order:4711 Name:Jim Id:2
}
```

Please note that this won't work with ExpandoObject, as it is (currently) not possible to define attributes here. 

#### Multiple attributes

The MatchColumn and RetrieveColumn can be applied to as many properties as needed. If there are multiple MatchColumns, all properties need to be equal. If there are multiple retrieve columns, all values are retrieved. 

### Partially blocking

The lookup is a partially blocking transformation. It will block processing until all data is loaded from the lookup source into memory. After this it will become a non-blocking transformation. 
It will always take as much memory as the lookup table needs to be loaded fully into memory. You can restrict the number of rows stored in the input buffer - set the `MaxBufferSize` property to a value greater than 0. 
  
### Error Linking

This transformation allows you to redirect erroneous records. By default, any exception in your flow would bubble up into your application the stop the flow. If you want to redirect data rows that would raise an exception, use the `LinkErrorTo` method to send the faulted rows into an error data flow. [Read more about error linking](../dataflow/linking_execution.md).

### LookupTransformation Api documentation

The full class documentation can be found in the Api documentation.

- If you want to use it with objects, [use the LookupTransformation that accepts two data types](https://etlbox.net/api/ETLBox.DataFlow.Transformations.LookupTransformation-2.html).
- If you want to use it with ExpandoObjects, [use the default implementation ](https://etlbox.net/api/ETLBox.DataFlow.Transformations.LookupTransformation.html).







