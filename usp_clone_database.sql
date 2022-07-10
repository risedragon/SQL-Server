USE master
GO
CREATE OR ALTER PROC usp_clone_database 
    @source_db NVARCHAR(50), @dest_db NVARCHAR(50) = NULL, @overwrite INT = 0, @kill_sessions INT = 0, @backup_destdb INT = 1
AS
    DECLARE @backupsql NVARCHAR(200)
    DECLARE @restoresql NVARCHAR(4000) = ''
    DECLARE @bakupfile NVARCHAR(200)
    DECLARE @killsql NVARCHAR(1000)=''
    DECLARE @timestamp NVARCHAR(28)

    if @dest_db is NULL
        SET @dest_db = @source_db + '_clone'
    IF 
        (DB_ID(@source_db) IS NOT NULL) --Source Database Exists
        AND (DB_ID(@dest_db) IS NULL OR @overwrite = 1) -- Destination Database Not Exists or Agree to Overwrite
        -- No sessions Or Kill sessions
        AND (NOT EXISTS (SELECT spid FROM master.sys.sysprocesses where db_name(dbid) = @dest_db) OR @kill_sessions = 1)
    
        BEGIN
            -- Backup And Restore Destination Database
            IF DB_ID(@dest_db) IS NOT NULL AND @backup_destdb = 1
            BEGIN
                PRINT '---Backup Destination Database---'
                SET @timestamp = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
                SET @bakupfile = @dest_db + '_' + @timestamp + '.bak'
                SET @backupsql = 'BACKUP DATABASE [' + @dest_db + '] TO DISK = ''' + @bakupfile + ''''
                EXEC (@backupsql)

                select @restoresql = @restoresql + CONCAT('MOVE ''', name, ''' TO ''' , REPLACE(physical_name, RIGHT(physical_name,4), '_'+@timestamp+'_'+RIGHT(physical_name, 4)), ''', ')
                    from master.sys.master_files where DB_NAME(database_id) = @dest_db          
                SELECT @restoresql = CONCAT('RESTORE DATABASE [', @dest_db+'_BAK_'+@timestamp, '] FROM DISK = ''', @bakupfile, ''' WITH ' , @restoresql)       
                SET @restoresql = LEFT(@restoresql, len(@restoresql)-1)
                PRINT 'Restore Destination Database To ' + @dest_db+'_BAK_'+@timestamp
                EXEC (@restoresql)
            END

            -- Begin Clone Database
            -- Bckup Source Database
            SET @bakupfile = @source_db + '_' + FORMAT(GETDATE(), 'yyyyMMddHHmmss') + '.bak'
            SET @backupsql = 'BACKUP DATABASE [' + @source_db + '] TO DISK = ''' + @bakupfile + ''''
            PRINT '---Backup Source Database---'
            EXEC (@backupsql)
            -- Prepare Restore Sqlcmd
            SET @restoresql = ''

            -- Move Statement
            SELECT @restoresql = @restoresql + CONCAT('MOVE ''', name, ''' TO ''' , REPLACE(physical_name, SUBSTRING(physical_name, LEN(physical_name)-CHARINDEX('\',reverse(physical_name)) + 2, CHARINDEX('\',reverse(physical_name))- CHARINDEX('.',reverse(physical_name)) - 1), @dest_db), ''', ')
                from master.sys.master_files where DB_NAME(database_id) = @source_db
            -- Restore Sqlcmd
            SELECT @restoresql = CONCAT('RESTORE DATABASE [', @dest_db, '] FROM DISK = ''', @bakupfile, ''' WITH ' , @restoresql, CASE WHEN @overwrite = 1 THEN 'REPLACE' ELSE 'RECOVERY' END)
            -- Kill Connected sessions
            IF @kill_sessions = 1 AND EXISTS (select TOP 1 * from master.sys.sysprocesses where dbid = db_id(@dest_db))
                BEGIN
                    PRINT '---Kill Connected to Destination Database Sessions---'
                    select @killsql = @killsql + 'kill ' + CONVERT(varchar(5), spid) + ';' from master.sys.sysprocesses where dbid = db_id(@dest_db)
                    EXEC (@killsql)
                END
            PRINT '---Clone Sourece Database to Destination Database---'
            EXEC (@restoresql)
        END

--TEST
exec usp_clone_database 'AdventureWorks', 'AdventureWorks_new', @kill_sessions=1, @overwrite=1, @backup_destdb=1

