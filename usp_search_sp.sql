CREATE OR ALTER PROC usp_search_sp 
    @dbname SYSNAME=NULL, 
    @name NVARCHAR(100) = NULL, 
    @dml NVARCHAR(100) = N'SELECT, INSERT, UPDATE, DELETE'
AS
    DECLARE @sqlcmd NVARCHAR(2000)='',
            @condition NVARCHAR(200)='',
            @condition2 NVARCHAR(200)='',
            @columns NVARCHAR(200)=''
    SET @dml = REPLACE(@dml, ' ', '')
    SELECT @sqlcmd = @sqlcmd +'IIF(charindex('''+value+''', m.definition)>0, 1, 0) [' + value + '],' from string_split(@dml, ',')
    SET @condition = IIF(@dml IS NULL, '',' ([' + REPLACE(@dml, ',', ']=1 OR [') + ']=1)')
    SET @condition2 = IIF(@name is null, '', ' [name] like ''%' + @name + '%''')
    SET @columns = IIF(@dml IS NULL, '',' ,[' + REPLACE(@dml, ',', '], [' )+']')
    SET @sqlcmd = N'
    WITH cte AS(
    select o.name, ' + @sqlcmd + 'm.definition ' + 'from sys.all_sql_modules m 
        left JOIN sys.all_objects o on m.object_id = o.object_id 
        WHERE o.[type] = ''P'')
    SELECT [name], definition' + @columns + ' FROM cte ' +
        IIF(@name IS NULL, '', 'WHERE '+ @condition2) +
        IIF(@dml is null, '', IIF(@name is null, ' where ',' and ') + @condition)
    
    IF DB_ID(@dbname) > 0
        BEGIN
            DECLARE @exec NVARCHAR(200) = QUOTENAME(@dbname)+N'.sys.sp_executesql '
            EXEC @exec @sqlcmd
        END
    ELSE
        exec (@sqlcmd)
GO
--test
exec usp_search_sp @dbname ='Orders',@name='usp', @dml='select'
exec usp_search_sp @name='usp', @dml='select, update, where, go, delete'
exec usp_search_sp @dml='update, where, go, delete, NOCOUNT'