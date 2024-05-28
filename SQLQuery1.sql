--create database netflix;
use netflix;

-- handling foreign chars
--removiong duplicates
--data type convertion
-- identify and populate missing values
--new dimension table for for countries and listed in for data analysis

select * from netflix_row;


create table netflix_clean(
show_id varchar(10),
type varchar(25),
title nvarchar(200),
director varchar(100),
cast 

