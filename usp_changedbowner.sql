-- Create Procedure to Change User Databases Owner
CREATE OR ALTER PROC usp_changedbowner @owner varchar(60) = 'sa'
AS
DECLARE @sqlcmd VARCHAR(2000) = ''
SELECT @sqlcmd = CONCAT(@sqlcmd, 'EXEC ', name, '..sp_changedbowner ', @owner, ';', CHAR(10)) 
    FROM master.sys.databases where SUSER_SNAME(owner_sid) <> @owner and database_id > 4

EXEC (@sqlcmd)

-- Change All User Databases Owner to sa
EXEC usp_changedbowner
