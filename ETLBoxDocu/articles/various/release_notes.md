# Release notes

## Version 2.3.2

### Features 

*General*: 
- Auto generated xml documentation added to package - now visible with Intellisense or when browsing package content.

*DataFlow*: 
- ExcelSource exposes parsed header names in FieldHeaders property.
- DbSource has ColumnConverters property

## Version 2.3.1

### Features

*ConnectionManagers*:
- ODBC/OleDb now have ConnectionManagerType property settable. 

*ControlFlow*:
- Db2 now has support for schemas
- CreateTableTask: Now offers functionality to alter tables (Alter() / CreateOrAlter()) 
- CreateSchemaTask supports authorization
- Added GetTableListTask (return all tables in database)

*DataFlow*:
- UnparsedData property for streaming sources now contains data of skipped rows.
- All executable sources allow to set limit for records to read
- Added property KeepIdentity to DbDestination which allows overwriting of Identity columns
- DataConverters available for DbDestination (allows to add custom column converter)
- (Breaking Change) DbSource: Replace List<string>ColumnNames prop with ICollection<ColumnMap> ColumnMapping 
- (Breaking change) Improved naming in ColumnMap Attribute (NewName = PropertyName, CurrentName = DbColumnName)
- (Breaking change) ColumnRename now uses RenameColumn attribute instead ColumnMapping. 

### Bug fixes 

- Postgres connection manager now has full support for jsonb columns.  
- DbSource/Sql property: Whitespace in column aliases are now properly parsed as column names.
