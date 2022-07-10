-- Create Proc To List Job history filter by job name  and days

CREATE OR ALTER PROC usp_job_history @jobs VARCHAR(100)='', @days INT = 30
AS
    DECLARE @startday INT = cast(format(DATEADD(d, -@days, GETDATE()),'yyyyMMdd') as int)
    DECLARE @sql NVARCHAR(MAX)
    SET @jobs = REPLACE(@jobs,' ','')

    SET @sql = N'SELECT j.name, h.* FROM sysjobhistory h LEFT JOIN sysjobs j on j.job_id = h.job_id WHERE h.run_date > @lastday AND j.name like '''
    SET @sql = @sql + '%' + REPLACE(@jobs,',','%'' UNION ' +@sql + '%') + '%'''

    EXEC sp_executesql @sql, N'@lastday INT', @startday

-- List Reindex and Backup job history
EXEC usp_job_history 'Reindex, Backup', 30