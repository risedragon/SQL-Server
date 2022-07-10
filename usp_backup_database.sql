CREATE OR ALTER PROCEDURE usp_backup_database @dbname NVARCHAR(80)
AS
    DECLARE @backupfile NVARCHAR(200)
    SET @backupfile = @dbname+'/'+@dbname+N'_'+FORMAT(GETDATE(), 'yyyyMMdd')+N'.bak'
    -- Full Backup
    IF NOT EXISTS
    (SELECT * FROM msdb.dbo.backupmediafamily WHERE physical_device_name LIKE '%'+@backupfile)
    OR (DATABASEPROPERTYEX(@dbname, 'Recovery') = 'FULL' AND 
            NOT EXISTS (SELECT bs.database_name, bs.recovery_model FROM msdb.dbo.backupmediafamily bf 
                INNER JOIN msdb.dbo.backupset bs 
                on bf.media_set_id = bs.media_set_id 
                WHERE bf.physical_device_name LIKE '%'+@backupfile 
                    and bs.recovery_model = 'FULL' 
                    and bs.database_name = @dbname))
        BEGIN
            EXEC ('BACKUP DATABASE ['+@dbname + '] TO DISK = '''+ @backupfile +''' WITH NAME = ''Full Backup''')
        END
    ELSE
        BEGIN
        -- Backup Log
        IF DATABASEPROPERTYEX(@dbname, 'Recovery') = 'FULL' AND 
            EXISTS (SELECT bs.database_name, bs.recovery_model FROM msdb.dbo.backupmediafamily bf 
                INNER JOIN msdb.dbo.backupset bs 
                on bf.media_set_id = bs.media_set_id 
                WHERE bf.physical_device_name LIKE '%'+@backupfile 
                    and bs.recovery_model = 'FULL' 
                    and bs.database_name = @dbname)
            BEGIN
                EXEC ('BACKUP LOG ['+ @dbname +'] TO DISK = ''' + @backupfile + ''' WITH NAME = ''Log Backup''')
            END
        END



-- Backup All Databases
DECLARE @sqlcmd VARCHAR(max) = ''
select @sqlcmd = @sqlcmd + 'EXEC usp_backup_database ' + name +';'+char(10) 
    from master.sys.databases where name <> 'tempdb'
exec (@sqlcmd)
