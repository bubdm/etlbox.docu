# Transformations

## Overview 

This article will give you an overview of all transformations that currently exist in ETLBox. If you already know what kind of transformation you are looking for, you can visit directly the article that goes more into the details.

- [Read more about row transformations, duplication and manipulations](../transformations/row_manipulations.md)
- [Read more about data retrieval](../transformations/lookup_data.md)
- [Read more about broadcasting, joining, splitting or merging data](../transformations/broadcast_merge_join.md)
- [Read more about aggregating data and block transformation](../transformations/aggregating_data.md)

## Transformation concepts

Transformations always have at least one input and one output. Inputs can be connected either to other transformations or sources, and the output can also connect to other transformations
or to destinations. 
The purpose of a transformation component is to take the data from its input(s) and post the transformed data to its outputs. This is done on a row-by-row basis.
As soon as there is any data in the input, the transformation will start and post the result to the output. 


### Buffering

Every transformation will come with an input buffer. If the transformation receives more data in its input than it is able to process, the buffer will hold this data until the transformation can continue with the next row. This buffering mechanism improves general throughput. E.g. a data source can read all data as fast as possible, as there will always be an input buffer in the transformation that will accept and buffer the record in memory. Whenever the transformation is ready for the next record there is will always be one in the buffer waiting for processing.

Some transformation will also have an output buffer. This depends on the specific transformations. Also, every destination component comes with an input buffer.  

#### Restricting buffer size

By default, all input (and output) buffers don't have a limitation how much rows they buffer. Though rows are constantly are removed when processing continues, sometimes there can be a bottleneck where a buffer become bigger and bigger because the processing in the flow doesn't continue fast enough. Normally, there is enough free memory available to handle this. But if needed you can restrict the amount of rows stored in the buffer. Every data flow component has the property `MaxBufferSize`. If set to a value greater than 0, e.g. 500, it will only allow up to 500 rows in the buffer(s) of the component..

### Non-Blocking and Blocking transformations

Transformation can be either blocking or non-blocking. 

Non-Blocking transformations will start to process data as soon as it finds something in its input buffer. 
In the moment where it discovers data in there, it will  start to transform it and send the data to registered output components. Using only non-blocking transformation is the fastest way to get data through the data flow pipeline. 

Blocking transformations will stop the data processing for the whole flow - the input buffer will wait until all data has reached the input. This means it will wait until all components connected to this transformation have read all data from their source. 
When all data was read from the connected sources and transformations further down the pipe, the blocking transformation will start its processing. Though this will reduce speed of your flow and consume more memory, the benefit of a blocking transformation is that you will have access to all data in the memory. Sometimes this is mandatory, e.g. if you want to sort data. The sort will always wait until all data has reached the transformation - only then it is able to sort it and post the sorted data to its output. 

Some transformation are partially blocking. This means that they are not blocking the whole flow like a blocking transformation - still some part of it will block. E.g. the Lookup transformation will read data from a lookup source into memory the first time data arrives - this does block the flow until the lookup source data is loaded. After this, the lookup is behaves basically like a non blocking transformation. 

## Row manipulations

### RowTransformations

The RowTransformation is the simplest but most powerful transformation in ETLBox. The generic transformation has two types 
- the type of the input data and the type of the output data. When creating a RowTransformation, you pass a transformation functions
describing how each record in the data flow is transformed. Here you can add any C# code that you like. 

The RowTransformation is a non blocking transformation, so it won't use up much memory even for high amounts of data.

```C#
RowTransformation<InputType,OutputType> trans = new RowTransformation<InputType,OutputType>(
    row => {
        return new OutputType() { Value = row.Value + 1 };
    });
```

### RowDuplication

Sometimes you want to duplicate the rows of your input data. This can be easily done with the RowDuplication transformation -
it will give you one or more duplicates of your data. If you want only to duplicate particular rows, you can pass a 
Predicate expression that define which rows can be clones and which not.

The RowDuplication is a non blocking transformation. 

Here a simple example for creating three duplicates of each row:

```C#
var source = new DbSource<InputType>("SourceTable");
RowDuplication<InputType> duplication = new RowDuplication<InputType>(3);
var dest = new CsvDestination<InputType>("output.csv");
source.LinkTo(duplication).LinkTo(dest);
```

### RowMultiplication

The RowMultiplication component is a variant of the RowTransformation. Like the RowTransformation, it accepts an input and an output type, and a transformation function (called MultiplicationFunc). The difference to the RowTransformation is that the multiplication function returns an array or list as return type. So from one input record you are able to create a transformation that returns one or more output records.

The RowMultiplication is a non blocking transformation. 

```C#
DbSource<InputRow> source = new DbSource<InputRow>("SourceTable");
RowMultiplication<InputRow, OutputRow> multiplication = new RowMultiplication<InputRow, OutputRow>(
    row =>
    {
        List<OutputRow> result = new List<OutputRow>();
        result.Add(new OutputRow(row.Value1));
        result.Add(new OutputRow(row.Value2));
        return result;
    });
DbDestination<OutputRow> dest = new DbDestination<OutputRow>("DestinationTable");
source.LinkTo(multiplication);
multiplication.LinkTo(dest);
```

### ColumnRename

ColumnRename allows you to rename the column or properties names of your ingoing data. 
You can provide a column mapping with the old and the new name for each column. The mapping can also be automatically retrieved from existing ColumnMap attributes. 

This transformation works with objects, ExpandoObjects and arrays as input data type. It will always output an ExpandoObject with the new mapped property names.    

If you have an array as input type, instead of providing the old name you need to enter the array index and the new name. 

```
var source = new DbSource<MyInputRow>();
var map = new ColumnRename<MyInputRow>();
map.ColumnMapping = new List<ColumnMapping>()
{
    new ColumnMapping("OldCol1","Col1"),
    new ColumnMapping("OldCol2","Col2"),
};
var dest = new DbDestination(SqlConnection, "ColumnRenameDest");

source.LinkTo<ExpandoObject>(map).LinkTo(dest);
```

## Data lookup

### LookupTransformation

The lookup transformation enriches the incoming data with data from the lookup source. To achieve this, all or some data from the lookup source is read into memory when the first record arrives. For each incoming row, the lookup tries to find a matching record in the in-memory table. If found, it uses this pre-loaded record to add additional data to the ingoing row. 

E.g. you have an order record that contains a customer name. This is your ingoing record into the lookup. Also, the lookup gets a table containing customer names and their ids as lookup source. Then the lookup can retrieve the customer id and update the property value in your order record during.

The lookup is a partially blocking transformation.
 
```C#
public class Order
{    
    public int OrderNumber { get; set; }    
    public int CustomerId { get; set; }    
    public string CustomerName { get; set; }    
}

public class Customer
{   
    [RetrieveColumn(nameof(Order.CustomerId))]
    public int Id { get; set; }
    
    [MatchColumn(nameof(Order.CustomerName))]
    public string Name { get; set; }
}

DbSource<Order> orderSource = new DbSource<Order>("OrderData");
CsvSource<Customer> lookupSource = new CsvSource<Customer>("CustomerData.csv");
var lookup = new LookupTransformation<Order, Customer>();
lookup.Source = lookupSource;
DbDestination<Order> dest = new DbDestination<Order>("OrderWithCustomerTable");
source.LinkTo(lookup).LinkTo(dest);
```


## Broadcasting and merging data

In some of your data flow you may want to clone the data into multiple outputs and have it processed differently in the further flow.
E.g. your data comes from one source and you want parts of it written into one destination and parts of it
written into another. Or you like to split up data based on some conditions. For this purpose you can use the Multicast.

### Multicast

The `Multicast` is a component that broadcasts your data into all linked components. It has one input and two or more outputs.
The Multicast is a non-blocking operation. 

If you want to split data, you can use Predicates which allow you to let only certain rows pass to a linked destination.  See more about this in the [article about Predicates and linking](linking_execution.md)

```C#
Multicast<MyDataRow> multicast = new Multicast<MyDataRow>();
multicast.LinkTo(dest1);
multicast.LinkTo(dest2);
multicast.LinkTo(dest3);
```

### Merging data with MergeJoin

If you want to merge data in your data flow, you can use the `MergeJoin`. This basically joins the outcome
 of two sources or transformations into one data record.

The MergeJoin accepts two inputs and has one output. A function describes how the two inputs are combined into one output. 
E.g. you can link two sources with the MergeJoin, define  a method how to combine these records and produce a new merged output. If needed, you can define a comparison function which describes if two records should be joined if a match condition is met. MergeJoin is a non blocking transformation. 

```C#
MergeJoin<InputType1, InputType2, OutputType> join = new MergeJoin<InputType1, InputType2, OutputType>();
join.MergeJoinFunc =  (leftRow, rightRow) => {
    return new OutputType() {
        Result = leftRow.Value1 + rightRow.Value2
    };
});
source1.LinkTo(join.LeftInput);
source2.LinkTo(join.RightInput);
join.LinkTo(dest);
```

### CrossJoin

The CrossJoin allows you to combine every record from input with every records from the other input. E.g. if your left input has the input records 1 and 2, and your right input the records A, B and C, the CrossJoin will combine 1 with A, B and C and 2 with A, B and C.
The CrossJoin is a partial blocking transformation. 

```C#
CrossJoin<InputType1, InputType2, OutputType> crossJoin = new CrossJoin<InputType1, InputType2, OutputType>();
crossJoin.CrossJoinFunc = (inmemoryRow, passingRow) => {
    return new OutputType() {
        Result = leftRow.Value1 + rightRow.Value2
    };
});
source1.LinkTo(join.InMemoryTarget);
source2.LinkTo(join.PassingTarget);
join.LinkTo(dest);
```

## Aggregating data 

### Aggregation

The aggregation allows you to aggregate data in your flow. You can either define your own aggregation function or use one of the default functions. The default aggregation functions are Sum, Min, Max, Count, FirstValue and LastValue. The aggregation does not necessarily to be calculated on your whole data. You can specify that your data is grouped (similar to a group BY). 

The Aggregation is basically a blocking transformation, but with a lower memory consumption. It will only store aggregated values in memory, not the detail rows itself. The calculation of the aggregated values is updated every time a record arrives at the Aggregation. This is why there is limitation of what kind of calculation can be performed. 

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
    
var source = new DbSource<MyDetailValue>("DetailValues");
var agg = new Aggregation<MyDetailValue, MyAggRow>();
var dest = new MemoryDestination<MyAggRow>();
source.LinkTo<MyAggRow>(agg).LinkTo(dest);
```


### BlockTransformation

A BlockTransformation waits until all data is received at the BlockTranformation - then it will be available in a List object and you can do modifications or calculations on your whole data set. Keep in mind that this transformation will need as much memory as the amount of data you loaded. 

```C#
BlockTransformation<InputType> block = new BlockTransformation<InputType>(
    inputData => {
        inputData.RemoveRange(1, 2);
        inputData.Add(new InputType() { Value = 1 });
        return inputData;
    });
```

## Other transformations

### Sort

A sort will wait for all data to arrive and then sort the data based on the given sort method. This is a blocking transformation, because data can only be sorted when all records are available in memory.  

```C#
Comparison<MySimpleRow> comp = new Comparison<MySimpleRow>(
        (x, y) => y.Col1 - x.Col1
    );
Sort<MySimpleRow> block = new Sort<MySimpleRow>(comp);
```

- [Read more about the sort and other transformations](../transformations/other.md)

### XmlSchemaValidation

This transformation allows you to validate XML code in your incoming data against a XML schema definition. You need to define how the XML string can be read from your data row and the schema definition used for validation. If the schema is not valid, the complete row will be send to the error output of the transformation. 

```C#
XmlSchemaValidation<MyXmlRow> schemaValidation = new XmlSchemaValidation<MyXmlRow>();
schemaValidation.XmlSelector = row => row.Xml;
schemaValidation.XmlSchema = xsdMarkup;
source.LinkTo(schemaValidation);
schemaValidation.LinkTo(dest);
schemaValidation.LinkErrorTo(error);
```

- [Read more about the xml connector and xml validation](../connectors/xml.md)