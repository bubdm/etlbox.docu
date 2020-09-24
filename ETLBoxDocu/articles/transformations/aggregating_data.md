# Aggregating data

## Aggregation

The aggregation class let you aggregate your data by with either your own aggregation function or a default function. This can be done on your whole data or on particular groups of your data (similar to a GROUP BY in sql)
Default functions are currently sum, min, max and count. The number of calculation is restricted because the calculation of the aggregated value is performed every time a record arrives at the destination, by using the current aggregated value and the new record. The reason for this limitation is the reduced memory consumption - only the aggregated value for each group us stored in memory, not the detail values. 
This approach works very well if you want to calculate a sum, min or max value or simply want to count your data. This sounds very basic, but these base values will also allow you to perform more calculation (e.g. the average a sum divided by the count.)

Here's an example how the calculation of the sum is done:
Our input data values would be 5, 3 and 2. First, the 5 would arrive. The aggregated value is 0 (default) + 5, so a 5 is stored. When the 3 arrives, the aggregated value is updated to 8. Now the 2 comes in, we store the 10, which is the result of the aggregation. The 10 is then passed to the output of the Aggregation. 

The aggregation also allows you to create your own aggregation function - with the same limitation: you only have access to the current aggregated value and the last record. If you need to perform a calculation on your whole data set, see below at the BlockTransformation. 


### Example aggregations on all data 

#### Using AggregateColumn attribute

There are two ways to use the Aggregation. The easier way is to make use of the attributes `AggregateColumn` and `GroupColumn` and using the default aggregation functions. Here is an example for an aggregation using only the `AggregateColumn`. If no `GroupColumn` is defined, the calculation is always done on all incoming data records. 

```C#
public class MyDetailValue
{
    public int DetailValue { get; set; }
}

public class MyAggRow
{
    [AggregateColumn(nameof(MyDetailValue.DetailValue), AggregationMethod.Sum)]
    public int AggValue { get; set; }
}

public static void Main()
{
    var source = new MemorySource<MyDetailValue>();
    source.DataAsList.Add(new MyDetailValue() { DetailValue = 5 });
    source.DataAsList.Add(new MyDetailValue() { DetailValue = 3 });
    source.DataAsList.Add(new MyDetailValue() { DetailValue = 2 });

    var agg = new Aggregation<MyDetailValue, MyAggRow>();

    var dest = new MemoryDestination<MyAggRow>();

    source.LinkTo<MyAggRow>(agg).LinkTo(dest);
    source.Execute();
    dest.Wait();

    foreach (var row in dest.Data)
        Console.WriteLine($"Sum:{row.AggValue}");

    //Output
    //Sum:10
}
```

#### Using aggregation action

You can achieve the same behavior as above with your own aggregation function. To do so you define an action how the aggregated value is updated when a new values arrives in the property AggregationAction. 

As a sum is easy to implement, your code would look like this: 

```C#
public class MyDetailValue
{
    public int DetailValue { get; set; }
}

public class MyAggRow2
{            
    public int AggValue { get; set; }
}

public static void Main()
{
    var source = new MemorySource<MyDetailValue>();
    source.DataAsList.Add(new MyDetailValue() { DetailValue = 5 });
    source.DataAsList.Add(new MyDetailValue() { DetailValue = 3 });
    source.DataAsList.Add(new MyDetailValue() { DetailValue = 2 });

    var agg = new Aggregation<MyDetailValue, MyAggRow2>();
    agg.AggregationAction =
        (detailValue, aggValue) =>
            aggValue.AggValue = detailValue.DetailValue + aggValue.AggValue;

    var dest = new MemoryDestination<MyAggRow2>();

    source.LinkTo<MyAggRow2>(agg).LinkTo(dest);
    source.Execute();
    dest.Wait();

    foreach (var row in dest.Data)
        Console.WriteLine($"Sum:{row.AggValue}");

    //Output
    //Sum:10
}
```

### Example aggregation with grouping

#### Using GroupingColumn

Having the aggregation on all your data records is probably most of the time not what you need. Often you would have to classify your data based on particular properties, and then have aggregation build for each class. This is called grouping and works similar like the GROUP BY clause in sql - you define which properties are used for grouping, and the calculations is done sepearately for each group. 

Let's define a basic exmaple: 
Our input data is "A":3, "A":7, "B":4 and "B":6. We are interest in the sum of the numbers. If we would do a normal aggregation without the number, the overall result would 20. Now we want to group our data by the letter. Then the result for group "A" would be 10 and for group "B" also 10. 

Codewise this would look like this, when we use the GroupColumn attribute

```C#
public class DetailWithGroup
{
    public int DetailValue { get; set; }
    public string Group { get; set; }
}

public class MyAggRow3
{
    [AggregateColumn(nameof(DetailWithGroup.DetailValue), AggregationMethod.Sum)]
    public int AggValue { get; set; }
    [GroupColumn(nameof(DetailWithGroup.Group))]
    public string Group { get; set; }
}

public static void Main()
{
    var source = new MemorySource<DetailWithGroup>();
    source.DataAsList.Add(new DetailWithGroup() { Group = "A", DetailValue = 3 });
    source.DataAsList.Add(new DetailWithGroup() { Group = "A", DetailValue = 7 });
    source.DataAsList.Add(new DetailWithGroup() { Group = "B", DetailValue = 4 });
    source.DataAsList.Add(new DetailWithGroup() { Group = "B", DetailValue = 6 });

    var agg = new Aggregation<DetailWithGroup, MyAggRow3>();

    var dest = new MemoryDestination<MyAggRow3>();

    source.LinkTo<MyAggRow3>(agg).LinkTo(dest);
    source.Execute();
    dest.Wait();

    foreach (var row in dest.Data)
        Console.WriteLine($"Sum for {row.Group}:{row.AggValue}");

    //Output
    //Sum for A:10
    //Sum for B:10
}
```

Please note that the GroupColumn is also used as attribute on the aggregated value - it needs to name of the property in the details object on which the grouping is based on. 

#### Using grouping function

Of course you can also create your own grouping function. If you want to do this, you actually need two functions: 
- A GroupingFunc that defines an object that is used for grouping. You can define an object here, thought we recommend to use or create a unique string or number that is used for comparison. 
- A StoreKeyAction that describe how the object used for grouping is stored in your aggregation object. 

Here is an example that uses a custom aggregation action as well as custom functions for grouping.

```C#
 public class MyAggRow4
{
    public int AggValue { get; set; }
    public string Group { get; set; }
}

public static void Main()
{
    var source = new MemorySource<DetailWithGroup>();
    source.DataAsList.Add(new DetailWithGroup() { Group = "A", DetailValue = 3 });
    source.DataAsList.Add(new DetailWithGroup() { Group = "A", DetailValue = 7 });
    source.DataAsList.Add(new DetailWithGroup() { Group = "B", DetailValue = 4 });
    source.DataAsList.Add(new DetailWithGroup() { Group = "B", DetailValue = 6 });

    var agg = new Aggregation<DetailWithGroup, MyAggRow4>();

    agg.AggregationAction =
        (detailValue, aggValue) =>
            aggValue.AggValue = detailValue.DetailValue + aggValue.AggValue;

    agg.GroupingFunc =
        detailValue => detailValue.Group;

    agg.StoreKeyAction =
        (groupingObject, aggValue) => aggValue.Group = (string)groupingObject;

    var dest = new MemoryDestination<MyAggRow4>();

    source.LinkTo<MyAggRow4>(agg).LinkTo(dest);
    source.Execute();
    dest.Wait();

    foreach (var row in dest.Data)
        Console.WriteLine($"Sum for {row.Group}:{row.AggValue}");

    //Output
    //Sum for A:10
    //Sum for B:10
}
```


#### Multiple attributes

The AggregateColumn and GroupColumn can be applied to as many properties as needed. You can use different aggregation function for each AggregateColumn. If there are multiple grouping columns, the combination of all columns is used to create the grouping key (which means that if all columns match they are in the same group).

Here is an example for an object used as output for an aggregation with multiple attributes

```C#
public class MyAggRow
{
    [AggregateColumn("Price", AggregationMethod.Sum)]
    public int AggPrice { get; set; }

    [AggregateColumn("OrderNumber", AggregationMethod.Count)]
    public int CountOrders { get; set; }

    [GroupColumn("OrderNumber")]
    public string OrderNumberGroupKey { get; set; }

    [GroupColumn("OrderDate")]
    public string OrderDateGroupKey { get; set; }

    public decimal AveragePrices => AggPrice / CountOrders;
}
```

### Blocking transformation

The aggregation is a blocking transformation. It will block processing until all records arrived at the aggregation. Then the aggregated values are written into the output. Because of the special calculation operation, the memory consumption will be moderate. 
The aggregation has an input and output buffer. You can't restrict the number of rows stored in the input buffer. You can restrict the amount of records in the output buffer - set the `MaxBufferSize` property to a value greater than 0. Restricting the output buffer is not recommended.
  
### Error Linking

This transformation allows you to redirect erroneous records. By default, any exception in your flow would bubble up into your application the stop the flow. If you want to redirect data rows that would raise an exception, use the `LinkErrorTo` method to send the faulted rows into an error data flow. [Read more about error linking](../dataflow/linking_execution.md).

### Aggregation Api documentation

The full class documentation can be found in the Api documentation.

- If you want to use it with objects, [use the Aggregation that accepts two data types](https://etlbox.net/api/ETLBox.DataFlow.Transformations.Aggregation-2.html).
- If you want to use it with ExpandoObjects, [use the default implementation ](https://etlbox.net/api/ETLBox.DataFlow.Transformations.Aggregation.html).


## BlockTransformation


The BlockTransformation waits until all data is has arrived. Then the data is available in a List object, and you can do any modifications or calculations that you want on your whole data set. This is a real blocking transformation: as it will block your flow until all data is in the in-memory list of the BlockTransformation, it will also need as much memory as the amount of data you load. 

Input and output type doesn't have to be the same. If you use the BlockTransformation with only one type, output type will be the same as the input type. If you define both types, you will have access to a list of all data of your InputType, and you are expected to return a list of your new data of your output type. 

The BlockTransformation does not care how many records are going in or out - both sets can be totally different. 

### Example

```C#
public class Order
{
    public int Price { get; set; }
    public string Day { get; set; }
}

public class AveragePerDay
{
    public int AveragePrice { get; set; }
    public int TotalOrders { get; set; }
    public string Day { get; set; }
}

public static void Main()
{
    var source = new MemorySource<Order>();
    source.DataAsList.Add(new Order { Price = 10, Day = "Monday" });
    source.DataAsList.Add(new Order { Price = 50, Day = "Monday" });
    source.DataAsList.Add(new Order { Price = 20, Day = "Tuesday" });
    source.DataAsList.Add(new Order { Price = 60, Day = "Tuesday" });
    source.DataAsList.Add(new Order { Price = 10, Day = "Wednesday" });

    var block = new BlockTransformation<Order, AveragePerDay>();
    block.BlockTransformationFunc =
        allOrders =>
        {
            var result = new List<AveragePerDay>();
            foreach (var weekDay in new List<string>() { "Monday", "Tuesday", "Wednesday" })
            {
                var weekdayOrder = allOrders.Where(order => order.Day == weekDay);
                var weekDayAverage = new AveragePerDay()
                {
                    Day = weekDay,
                    TotalOrders = weekdayOrder.Count(),
                    AveragePrice = weekdayOrder
                                    .Sum(o => o.Price)
                                    /
                                    weekdayOrder.Count()
                };

                result.Add(weekDayAverage);
            }
            return result;
        };

    var dest = new MemoryDestination<AveragePerDay>();

    source.LinkTo<AveragePerDay>(block).LinkTo(dest);
    source.Execute();
    dest.Wait();

    foreach (var row in dest.Data)
        Console.WriteLine($"Day:{row.Day} Totals:{row.TotalOrders} Average:{row.AveragePrice}");

    //Output
    //Day:Monday Totals:2 Average: 30
    //Day:Tuesday Totals:2 Average: 40
    //Day:Wednesday Totals:1 Average: 10
}
```


### Blocking transformation 

The BlockTransformation is a real blocking transformation. It will block processing until all records arrived, and use up as much memory as needed to store the incoming rows. After this, all rows are written into the output. 
The BlockTransformation has an input and output buffer. You can't restrict the number of rows stored in the input buffer. But you can restrict the amount of records in the output buffer - set the `MaxBufferSize` property to a value greater than 0. 
  
### Error Linking

There is no error linking available for the BlockTransformation.

### Aggregation Api documentation

The full class documentation can be found in the Api documentation.

- If you want to use it with different input and output types, [use the BlockTransformation that accepts two data types](https://etlbox.net/api/ETLBox.DataFlow.Transformations.BlockTransformation-2.html).
- If you want to use it with the same output type as the input, [use the BlockTransformation that accepts one data type](https://etlbox.net/api/ETLBox.DataFlow.Transformations.BlockTransformation-1.html).
- If you want to use it with ExpandoObjects, [use the default implementation ](https://etlbox.net/api/ETLBox.DataFlow.Transformations.BlockTransformation.html).

