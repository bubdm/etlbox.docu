# Excel

## Excel connector package

If you need to read from excel files, make sure to add the latest nuget package [with the excel connector for ETLbox](https://www.nuget.org/packages/ETLBox.Excel/)

The Excel connector only can read excel from a source. If you need to generate Excel output, consider to create csv files instead (which can be created with the `CsvDestination`)

### ExcelSource

An Excel source reads data from a xls or xlsx file. 
By default the excel reader will try to read all data in the file. You can specify a sheet name and a range 
to restrict this behavior. 

By default, a header column is expected in the first row. The name of the header for each columns
 is used to map the column with the object - if the property is equal the header name, the value of
 subsequent rows is written into the property.

### 3rd party libraries

The excel connector package [uses the 3rd party library `ExcelDataReader`](https://github.com/ExcelDataReader/ExcelDataReader). 

#### Example 

Let's consider an example. If your excel file looks like this:

Col1|Col2
-|-----
1|Test1
2|Test2
3|Test3

You can easily load this data with an object like this:

```C#

public class ExcelData {
    public string Col1 { get; set; }
    public int Col2 { get; set; }
}

ExcelSource<ExcelData> source = new ExcelSource<ExcelData> ("src/DataFlow/ExcelDataFile.xlsx");
```

You can change this behavior with the Attribute `ExcelColumn`.
Here you can either define a different header name used for matching for a property.
Or you can set the column index for the property - the first column would be 0, the 2nd column 1, ...
When you using the column index, you can read also from ExcelFile that have no header row. 
In this case, you need to set the property `HasNoHeader` to true when using the ExcelSource.

Usage example for an excel file that contains no header. This could like this:

 |
-|-----
1|Test1
2|Test2
3|Test3

This is the corresponding object creation:

```C#

public class ExcelData {
    [ExcelColumn(0)]
    public string Col1 { get; set; }
    [ExcelColumn(1)]
    public int Col2 { get; set; }
}

ExcelSource<ExcelData> source = new ExcelSource<ExcelData>("src/DataFlow/ExcelDataFile.xlsx") {
    Range = new ExcelRange(2, 4, 5, 9),
    SheetName = "Sheet2",
    HasNoHeader = true
};
```
The ExcelRange must not define the full range. It is sufficient if you just set the starting coordinates. The end of the
data can be automatically determined from the underlying ExcelDataReader.

The ExcelSource has a property `IgnoreBlankRows`. This can be set to true, and all rows which cells are completely empty
are ignored when reading data from your source. 

#### Using dynamic objects

The ExcelSource comes like all other components with the ability to work with dynamic object. 

Just define your ExcelSource like this:

```C#
ExcelSource source = new ExcelSource("src/DataFlow/ExcelDataFile.xlsx");
```

This will internally create an ExpandoObject for further processing. The property name will automatically be determined by the header column. If you don't have a header column, the property names would be `Column1` for the first, `Column2` for the second column and so on. 


