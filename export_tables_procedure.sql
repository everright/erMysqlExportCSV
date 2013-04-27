DELIMITER //
use test
DROP PROCEDURE IF EXISTS `export_tables` //
CREATE PROCEDURE `export_tables` (IN `dbname` VARCHAR(100), IN `quote` CHAR(2), IN `delimiter` CHAR(2), IN `export_dir` VARCHAR(200), IN `ingore_tables` TEXT)
 LANGUAGE SQL
 NOT DETERMINISTIC
 CONTAINS SQL
 SQL SECURITY DEFINER
 COMMENT 'Export in csv format with headers'
cont:BEGIN
/* This procedure has been created to add the column names as a header column 
   when exporting mysql tables.

Usage example: CALL export_tables('test', '"',',','/tmp/','sessions,cache');

*/
-- Declare some variables
   DECLARE done INT DEFAULT 0;
   DECLARE myTable VARCHAR(50);
   DECLARE curs CURSOR FOR SELECT table_name FROM `information_schema`.`tables` WHERE table_schema = `dbname`;
-- Declare a cursor
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
-- There don't need to be set (@variables don't exist outside the procedure, 
-- but I set them for easy reference anyway
   SET @myResult = '';
   SET @myHeader = '';
   SET @myResultSql = '';
   SET @myHeaderSql = '';
   SET @dbExist = 0;

-- Do some very simple checking for valid parameters
   SELECT COUNT(table_schema) INTO @dbExist FROM `information_schema`.`tables` WHERE table_schema = `dbname`;
   IF @dbExist < 1 THEN
       SELECT 'Parameter Error: database `dbname` not exist';
       LEAVE cont;
   END IF;

   IF LENGTH(`quote`) > 1 THEN 
       SELECT 'Parameter Error:  may not be more than 1 character';
       LEAVE cont;
   ELSEIF `quote` = '' THEN SET `quote` = '"';
   END IF;

   IF LENGTH(`delimiter`) > 1 THEN 
       SELECT 'Parameter Error:  may not be more than 1 character';
       LEAVE cont;
   ELSEIF `delimiter` = '' THEN SET `delimiter` = ',';
   END IF;

   IF RIGHT(`export_dir`,1) != '/' THEN 
       SELECT 'Paramater Error:  has to end in a /';
       LEAVE cont;
   ELSEIF LENGTH(`export_dir`) = 0 THEN SET `export_dir` = '/tmp/';
   END IF;

-- Initialise the cursor query
OPEN curs;

-- Set up a loop so we can traverse all the row in the cursor table
table_loop: LOOP

-- Get a tablename
   FETCH curs INTO myTable;
   IF `ingore_tables` != '' AND FIND_IN_SET(myTable, `ingore_tables`) THEN
      ITERATE table_loop;
   END IF;

   IF done THEN
      LEAVE table_loop;
   END IF;
-- Build a sql statement string that concatenates the column names from the 
-- information schema's 'columns' table to build a header for the csv file
   SET @myHeaderSql = concat('SELECT GROUP_CONCAT(', char(39), `quote`, char(39), ',
   COLUMN_NAME, ', char(39), `quote`, char(39), ' SEPARATOR ', char(39), `delimiter`,
   char(39), ') FROM `information_schema`.`columns` WHERE table_schema=', char(39),
   `dbname`, char(39), ' and table_name=', char(39), myTable, char(39),
   ' INTO @myHeader');
   PREPARE stmt1 FROM @myHeaderSql;
   EXECUTE stmt1;
-- Build the the sql statement string that will dump the data into the csv file
   SET @myResultSql = concat('SELECT * FROM ', `dbname`, '.', myTable, ' into OUTFILE ', 
   char(39), `export_dir`, myTable, '-', DATE_FORMAT(now(), '%Y%m%d-%H%i%s'), '.csv',
   char(39), ' FIELDS TERMINATED BY ', char(39), `delimiter`, char(39), 
   ' OPTIONALLY ENCLOSED BY ', char(39), `quote`, char(39), ' LINES TERMINATED BY ',
   char(39), '\n', char(39));
-- Use Union to combine the two parts
   SET @myResult = concat('SELECT ', @myHeader,' UNION ALL ',@myResultSql);
   PREPARE stmt2 FROM @myResult;
-- Sweet, now the files are being written!
   EXECUTE stmt2;

END LOOP;

CLOSE curs;

END
//
