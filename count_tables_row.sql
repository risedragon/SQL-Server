use AdventureWorks
exec sp_MSforeachtable @precommand=N'DROP TABLE IF EXISTS ##result; CREATE TABLE ##result (name VARCHAR(128), rows INT)', 
@command1 =N'INSERT ##result (name, rows) SELECT ''?'', count(*) FROM ?',
@postcommand = N'SELECT * FROM ##result ORDER BY rows DESC'