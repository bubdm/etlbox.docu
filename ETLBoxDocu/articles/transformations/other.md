# Other transformation

## BatchTransformation

The normal RowTransformation will execute custom code for every processed row. Sometimes it can be beneficial not only to process every row, but batches of incoming. For this purpose you can use the BatchTransformation. (Note: if you want to modify all of your input data at once, take a look at the BlockTransformation).

```C#
BatchTransformation<MyInputRow,MyOutputRow> batchtrans = new BatchTransformation<MyInputRow,MyOutputRow>();
batchtrans.BatchSize = 3;
batchtrans.BatchTransformationFunc =
    batchdata =>
    {
        List<MyOutputRow> result = new List<MyOutputRow>();
        foreach (var row in batchdata)
            result.Add(new MyOutputRow(row));
        return result;
    };
```

### CachedBatchTransformation

The CachedBatchTransformation has the same functionality as the BatchTransformation, but offers additionally a cache manager object to access previously processed batches of data. 

```C#
CachedBatchTransformation<MyRow> batchtrans = new CachedBatchTransformation<MyRow>();
var cm = (MemoryCache<MyRow,MyRow>)batchtrans.CacheManager;
cm.MaxCacheSize = 100;
batchtrans.BatchSize = 5;
batchtrans.BatchTransformationFunc =
    (batchdata, cache) =>
    {
        List<MyRow> result = new List<MyRow>();
        foreach (var row in batchdata)
            if (!(cache.Any(cacheRow => cacheRow.Id == row.Id)))
                result.Add(new MyOutputRow(row));
        return result;
    };
```

### Non blocking transformation

The BatchTransformation and CachedBatchTransformation are partial blocking transformations - they will keep batches of data in memory, and will wait until enough data has arrived at the transformation to fill a batch.  

## Distinct

The Distinct transformation will filter out duplicate records. For each incoming row, the distinct will create a hash value based on the values in the properties. This hash value will be stored in an internal list. If another record with the same hash values arrives, this record will be filtered out as it is a duplicate.
By default, all public properties are used for the hash value generation. You can use the attribute DistinctColumn to specify particular properties.

```C#
public class MyRow
{
    [DistinctColumn]
    public int DistinctId { get; set; }

    public string OtherValue { get; set; } 
}

Distinct<MyRow> trans = new Distinct<MyRow>();
```

### Non blocking transformation

The Distinct is a non blocking transformation - every row is send to the next component after the hash values was generated. 

## Sort

The sort is a simple transformation that sorts all you incoming data. You can specify the sorting method yourself by defining a Comparison function which is used for sorting.
A comparison function defines if one object is either smaller, greate or equal than another object. Based on this information your whole data set will be sort. 

```C#
Comparison<MySimpleRow> comp = new Comparison<MySimpleRow>(
        (x, y) => y.Col1 - x.Col1
    );
Sort<MySimpleRow> block = new Sort<MySimpleRow>(comp);
```

### Blocking transformation

This is a blocking transformation, because data can only be sorted when all records are available in memory.  Thus, it will always consume as much memory as needed to store all incoming rows. 
The Sort has an input and output buffer. You can't restrict the number of rows stored in the input buffer. But you can restrict the amount of records in the output buffer - set the `MaxBufferSize` property to a value greater than 0. 



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
