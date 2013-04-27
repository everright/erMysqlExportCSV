erMysqlExportCSV
================

Author: Everright.Chen
Email:  everright.chen@gmail.com
Web:    http://www.everright.cn

This procedure has been created to add the column names as a header column when exporting mysql tables.

How to configure and use
========================

Install
-------

Login MySQL command. 

    mysql> . /opt/export_tables_procedure.sql

Usage
-----

    mysql> use test;
    mysql> CALL export_tables('test', '"', ',', '/tmp/', 'sessions,cache');

Parameters
----------
    1: Database name
    2: "OPTIONALLY ENCLOSED BY" for output csv
    3: "FIELDS TERMINATED BY" for output csv
    4: Export destination for output csv
    5: Ingore tables, separated by commas, these tables will not be exported.
