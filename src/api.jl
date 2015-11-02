
function response_to_dataframe(session::HiveSession, response, fetchsize::Integer; cached_schema::Union{AbstractString,Symbol,Void}=nothing)
    ready = check_status(response.status)
    rs = result(session, ready, response.operationHandle)::ResultSet
    schema(rs; cached=cached_schema)
    fetchsize!(rs, fetchsize)
    dataframe(rs)
end

##
# A search pattern used in the below methods can have:
# '_': Any single character.
# '%': Any sequence of zero or more characters.
# '\': Escape character used to include special characters,
#      e.g. '_', '%', '\'. If a '\' precedes a non-special
#      character it has no special meaning and is interpreted
#      literally.

##
# Returns the list of catalogs (databases).
# Results are ordered by TABLE_CATALOG.
function catalogs(session::HiveSession; fetchsize::Integer=DEFAULT_FETCH_SIZE)
    conn = session.conn
    request = thriftbuild(TGetCatalogsReq, Dict(:sessionHandle => conn.handle.sessionHandle))
    response = GetCatalogs(conn.client, request)
    response_to_dataframe(session, response, fetchsize; cached_schema=:catalogs)
end

##
# Retrieves the schema names available in this database.
# The results are ordered by TABLE_CATALOG and TABLE_SCHEM.
function schemas(session::HiveSession; catalog_pattern::AbstractString="", schema_pattern::AbstractString="", fetchsize::Integer=DEFAULT_FETCH_SIZE)
    conn = session.conn

    request = thriftbuild(TGetSchemasReq, Dict(:sessionHandle => conn.handle.sessionHandle))
    isempty(catalog_pattern) || set_field!(request, :catalogName, catalog_pattern)
    isempty(schema_pattern) || set_field!(request, :schemaName, schema_pattern)

    response = GetSchemas(conn.client, request)
    response_to_dataframe(session, response, fetchsize; cached_schema=:schemas)
end

##
# Returns a list of tables with catalog, schema, and table type information.
# Results are ordered by TABLE_TYPE, TABLE_CAT, TABLE_SCHEM, and TABLE_NAME
function tables(session::HiveSession; catalog_pattern::AbstractString="", schema_pattern::AbstractString="", table_pattern::AbstractString="", table_types::Array=[], fetchsize::Integer=DEFAULT_FETCH_SIZE)
    conn = session.conn

    request = thriftbuild(TGetTablesReq, Dict(:sessionHandle => conn.handle.sessionHandle))
    isempty(catalog_pattern) || set_field!(request, :catalogName, catalog_pattern)
    isempty(schema_pattern) || set_field!(request, :schemaName, schema_pattern)
    isempty(table_pattern) || set_field!(request, :tableName, table_pattern)
    isempty(table_types) || set_field!(request, :tableTypes, convert(Array{UTF8String,1}, table_types))

    response = GetTables(conn.client, request)
    response_to_dataframe(session, response, fetchsize; cached_schema=:tables)
end

##
# Returns the table types available in this database.
# The results are ordered by table type.
function tabletypes(session::HiveSession; fetchsize::Integer=DEFAULT_FETCH_SIZE)
    conn = session.conn
    request = thriftbuild(TGetTableTypesReq, Dict(:sessionHandle => conn.handle.sessionHandle))
    response = GetTableTypes(conn.client, request)
    response_to_dataframe(session, response, fetchsize; cached_schema=:tabletypes)
end

##
# Returns a list of columns in the specified tables.
# Optional parameter `catalog` must contain a full catalog name.
# Optional parameters `schema_pattern`, `table_pattern` and `column_pattern` can contain a search pattern.
# Result Set Columns are the same as those for the ODBC CLIColumns function.
function columns(session::HiveSession; catalog::AbstractString="", schema_pattern::AbstractString="", table_pattern::AbstractString="", column_pattern::AbstractString="", fetchsize::Integer=DEFAULT_FETCH_SIZE)
    conn = session.conn

    request = thriftbuild(TGetColumnsReq, Dict(:sessionHandle => conn.handle.sessionHandle))
    isempty(catalog) || set_field!(request, :catalogName, catalog)
    isempty(schema_pattern) || set_field!(request, :schemaName, schema_pattern)
    isempty(table_pattern) || set_field!(request, :tableName, table_pattern)
    isempty(column_pattern) || set_field!(request, :columnName, column_pattern)

    response = GetColumns(conn.client, request)
    response_to_dataframe(session, response, fetchsize; cached_schema=:columns)
end

##
# Returns a list of functions supported by the data source.
# Catalog name must match the catalog name as it is stored in the database; "" retrieves those without a catalog; null means that the catalog name should not be used to narrow the search.
# Schema name pattern must match the schema name as it is stored in the database; "" retrieves those without a schema; null means that the schema name should not be used to narrow the search.
# Function name pattern must match the function name as it is stored in the database.
# The behavior of this function matches `java.sql.DatabaseMetaData.getFunctions()`.
function functions(session::HiveSession, function_pattern::AbstractString; catalog::AbstractString="", schema_pattern::AbstractString="", fetchsize::Integer=DEFAULT_FETCH_SIZE)
    conn = session.conn

    request = thriftbuild(TGetFunctionsReq, Dict(:sessionHandle => conn.handle.sessionHandle, :functionName => function_pattern))
    isempty(catalog) || set_field!(request, :catalogName, catalog)
    isempty(schema_pattern) || set_field!(request, :schemaName, schema_pattern)

    response = GetFunctions(conn.client, request)
    response_to_dataframe(session, response, fetchsize; cached_schema=:functions)
end

