create database netflix;

use netflix;



-- populate missing values in country, duration columns
-- drop rest of the nulls as not_available
-- drop columns director , listed_in, country, cast

-- handling foreign chars
select * 
from netflix_raw
where title like '?%';

drop table [netflix_raw];

create TABLE [dbo].netflix_raw(
	[show_id] [varchar](10) primary key ,
	[type] [varchar](10) NULL,
	[title] NVARCHAR(200) NULL,
	[director] [varchar](250) NULL,
	[cast] [varchar](1000) NULL,
	[country] [varchar](150) NULL,
	[date_added] [varchar](20) NULL,
	[release_year] int NULL,
	[rating] [varchar](10) NULL,
	[duration] [varchar](10) NULL,
	[listed_in] [varchar](100) NULL,
	[description] [varchar](500) NULL

	)
GO


----**********************************************************************************************************************************************************************************************************************************************************************************************************************************

-- removiong duplicates

with cte as (
select *, ROW_NUMBER() over(partition by title, type order by show_id) as rn
from netflix_raw)
select * from cte where rn = 1


----**********************************************************************************************************************************************************************************************************************************************************************************************************************************

--new table for listed_in, director and , country

select show_id, trim(value) as genre
into netflix_genre
from netflix_raw
cross apply string_split(listed_in, ',')
select * from netflix_genre


select show_id, trim(value) as director
into netflix_directors
from netflix_raw
cross apply string_split(director, ',')

select show_id, trim(value) as country
into movie_in_country
from netflix_raw
cross apply string_split(country, ',')
select * from movie_in_country


select show_id, trim(value) as cast
into cast_in_movie
from netflix_raw
cross apply string_split(cast, ',')
select * from cast_in_movie



----**********************************************************************************************************************************************************************************************************************************************************************************************************************************

-- drop columns director , listed_in, country, cast
alter table netflix_raw drop column cast, director, country, listed_in
select * from netflix_raw


----**********************************************************************************************************************************************************************************************************************************************************************************************************************************


-- data type conversions for date added
select show_id, type, title, cast(date_added as date) as date_added, release_year, rating, duration, description
from netflix_raw


----**********************************************************************************************************************************************************************************************************************************************************************************************************************************

-- populate missing values in country columns

select show_id, country 
from netflix_raw
where country is null

insert into movie_in_country
select show_id, dc.country 
from netflix_raw nr
inner join (
select director, country
from movie_in_country mc 
inner join netflix_directors nd
on mc.show_id = nd.show_id
group by director, country
) dc on nr.director = dc.director
where nr.country is null 

-- populate missing values in duration columns and do with previous thing

with cte as (
select *, ROW_NUMBER() over(partition by title, type order by show_id) as rn
from netflix_raw )
select show_id, type, title, cast(date_added as date) date_added, release_year, rating, (case when duration is null then rating else duration end) as duration, description
into netflix_final
from cte
where rn = 1

----**********************************************************************************************************************************************************************************************************************************************************************************************************************************
select * from netflix_final

----**********************************************************************************************************************************************************************************************************************************************************************************************************************************
-- anaylsis
--1. which country has highest number of comedy movies

select top 1 country,  count(distinct ng.show_id) as cnt
from netflix_final nf
inner join movie_in_country mc
on nf.show_id = mc.show_id
inner join netflix_genre ng
on mc.show_id = ng.show_id
where type = 'Movie' and genre = 'Comedies'
group by country
order by cnt desc




--2.for each director count the number of movies and tv shows made by them in seperate columns for directors who have created movies and tv shows

select director, sum(case when type = 'Movie' then 1 else 0 end) as num_movies,
sum(case when type = 'TV show' then 1 else 0 end) as num_shows
from netflix_final nf
inner join netflix_directors nd
on nf.show_id = nd.show_id
group by director
having count(distinct(type)) > 1;





-- 3. for each year ( as per date added to netflix ) which director has max number of movies released


with cte as (
select director, year(date_added) as yr, count(1) as total_movies
from netflix_final nf
inner join netflix_directors nd
on nf.show_id = nd.show_id
where type = 'Movie'
group by director, year(date_added) ),
cte2 as (
select *, row_number() over(partition by yr order by total_movies desc) as rn
from cte)
select yr, director, total_movies
from cte2
where rn = 1;




-- 4. avg duration by movies in each genre
---select --, cast(duration as int)
---from netflix_final
---where duration not like '%season%'

select genre, avg(cast(substring(duration, 1, len(duration) - 4) as int)) as avg_movie_duration
from netflix_final nf
inner join netflix_genre ng
on nf.show_id = ng.show_id
where type = 'Movie' and duration not like '%season'
group by genre
order by genre;




-- 5. find the list of director who created horror and comedy both. display name with number of horror and comedy movies created

select director, sum(case when genre = 'Horror Movies' then 1 else 0 end ) as num_horror,
sum(case when genre = 'Comedies' then 1 else 0 end ) as num_Comedy
from netflix_final nf
inner join netflix_genre ng
on nf.show_id = ng.show_id
inner join netflix_directors nd
on nf.show_id = nd.show_id
where type = 'Movie' and genre in ('Horror Movies', 'Comedies')
group by director
having count(distinct (genre)) = 2;