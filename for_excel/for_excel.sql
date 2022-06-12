# 1. 中文表 9UVGU5QQ
select *
from (select m.ImdbId,
             m.Title,
             mcta.chineseTitle,
             mla.languageInChinese,
             m.Language,
             m.Country,
             m.Director,
             m.Genre,
             m.Imdb250Day,
             m.kind,
             m.Year,
             mla.originalLanguage
      from movie_basic_info m
               left join movie_chinese_title_audited mcta on m.ImdbId = mcta.ImdbId
               left join movie_language_audited mla on mcta.ImdbId = mla.ImdbId) a,
     movies_analysis_list
where a.ImdbId = movies_analysis_list.ImdbId
  and movies_analysis_list.isNeedAnalysis = 'y';

#---------------------------------------------------------------------------------------------------------------------#
# 2. 语言种类表 BDX8SRX9
select *
from (select originalLanguage
      from tmdb_movie_chinese,
           movies_analysis_list
      where tmdb_movie_chinese.ImdbId = movies_analysis_list.ImdbId
        and movies_analysis_list.isNeedAnalysis = 'y'
      group by originalLanguage) as languageCodeTable
         left join language_conversion on languageCodeTable.originalLanguage = language_conversion.languageCode;
#---------------------------------------------------------------------------------------------------------------------#

# 3. 在榜时间表 9X3KC8SR
## 3-1 临时表1 9X3KC8SR
create table if not exists start_end_day_temp
select ImdbId, Title, min(day) startDay, max(day) endDay, count(day) dayCount
from imdb_history
where day < '2022-01-01'
group by ImdbId, Title;
## 3-2 临时表2 9X3KC8SR
create table if not exists start_end_day_serial_number_temp
select startEndDayTable.ImdbId   ImdbId,
       startEndDayTable.Title    movieTitle,
       startEndDayTable.startDay startDay,
       daylist1.serialNumber     startDayNumber,
       startEndDayTable.endDay   endDay,
       daylist2.serialNumber     endDayNumber,
       startEndDayTable.dayCount
from start_end_day_temp as startEndDayTable
         left join imdb_250_day_list as daylist1 on startday = daylist1.day
         left join imdb_250_day_list as daylist2 on endday = daylist2.day;

## 3-3 临时表3 9X3KC8SR
create table if not exists movie_duration_temp
select ImdbId,
       movieTitle,
       startDay,
       startDayNumber,
       endDay,
       endDayNumber,
       dayCount,
       (endDayNumber - startDayNumber + 1)            duration,
       (endDayNumber - startDayNumber + 1 - dayCount) difference
from start_end_day_serial_number_temp;

## 3-4 查询 9X3KC8SR
select *
from movie_duration_temp,
     movies_analysis_list
where movie_duration_temp.ImdbId = movies_analysis_list.ImdbId
  and movies_analysis_list.isNeedAnalysis = 'y'
order by movie_duration_temp.endDay desc, movie_duration_temp.startDay;

## 3-5 删除临时表 9X3KC8SR
drop table if exists movie_duration_temp;
drop table if exists start_end_day_serial_number_temp;
drop table if exists start_end_day_temp;
#---------------------------------------------------------------------------------------------------------------------#

# 4. 生成导演表 单行变多行 JSLA2ZY8
SELECT mda.ImdbId
     , mda.chineseTitle
     , mda.ImdbTitle
     , substring_index(substring_index(mda.director, ';', b.help_topic_id + 1), ';', - 1) AS director
FROM movies_director_audited mda
         INNER JOIN mysql.help_topic b
                    ON b.help_topic_id < (length(mda.director) - length(REPLACE(mda.director, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y');
#---------------------------------------------------------------------------------------------------------------------#

# 5. 每个电影导演的电影数量 SPHW52XE
## 5-1 临时表1 SPHW52XE
create table if not exists director_movie_single_temp
SELECT mda.ImdbId
     , mda.chineseTitle
     , mda.ImdbTitle
     , substring_index(substring_index(mda.director, ';', b.help_topic_id + 1), ';', - 1) AS director
FROM movies_director_audited mda
         INNER JOIN mysql.help_topic b
                    ON b.help_topic_id < (length(mda.director) - length(REPLACE(mda.director, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y');

## 5-2 查询 SPHW52XE
select director_movie_single_temp.director, count(*) number
from director_movie_single_temp
group by director
order by number desc;

## 5-3 删除临时表 SPHW52XE
drop table if exists director_movie_single_temp;
#---------------------------------------------------------------------------------------------------------------------#

# 6. 各语言数量 语言占比统计饼图_3FQHYAW2
select mla.languageInChinese as languages, count(mla.languageInChinese) as number
from movies_analysis_list mal,
     movie_language_audited mla
where mal.ImdbId = mla.ImdbId
  and mal.isNeedAnalysis = 'y'
group by mla.languageInChinese
order by number desc;
#---------------------------------------------------------------------------------------------------------------------#

# 7. 生成演员表 单行变多行 取一部电影前5位的演员 Z77MAPS2
SELECT maa.ImdbId
     , maa.chineseTitle
     , maa.ImdbTitle
     , substring_index(substring_index(maa.actor, ';', auto_id.id + 1), ';', - 1) AS actor
FROM movies_actor_audited maa
         JOIN auto_id
              ON auto_id.id < (length(maa.actor) - length(REPLACE(maa.actor, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y');
#---------------------------------------------------------------------------------------------------------------------#

# 8. 演员电影数量 取一部电影前5位的演员 3DHCJBWY
## 8-1 临时表1 3DHCJBWY
create table if not exists actor_movie_single_temp
SELECT maa.ImdbId
     , maa.chineseTitle
     , maa.ImdbTitle
     , substring_index(substring_index(maa.actor, ';', auto_id.id + 1), ';', - 1) AS actor
FROM movies_actor_audited maa
         JOIN auto_id
              ON auto_id.id < (length(maa.actor) - length(REPLACE(maa.actor, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y');

## 8-2 查询 3DHCJBWY
select actor_movie_single_temp.actor, count(*) number
from actor_movie_single_temp
group by actor
order by number desc;

## 8-3 删除临时表 3DHCJBWY
drop table if exists actor_movie_single_temp;
#---------------------------------------------------------------------------------------------------------------------#

# 9. 每年电影数量 电影与年对应关系 X8TJAGBA
## 9-1 临时表1 X8TJAGBA
create table if not exists movie_publish_year_temp
select *
from movies_publish_date_audited
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y');

## 9-2 临时表2 X8TJAGBA
create table if not exists each_year_movie_count_temp
select publish_year_imdb, count(*) number
from movie_publish_year_temp
group by publish_year_imdb
order by publish_year_imdb;

## 9-3 查询 需要年连续 X8TJAGBA
select timeline_year.the_year year, ifnull(each_year_movie_count_temp.number, 0) number
from timeline_year
         left join each_year_movie_count_temp on timeline_year.the_year = each_year_movie_count_temp.publish_year_imdb;

## 9-4 删除临时表 X8TJAGBA
drop table if exists each_year_movie_count_temp;
drop table if exists movie_publish_year_temp;
#---------------------------------------------------------------------------------------------------------------------#

# 10. 导演每年电影数量 GVEY2ZC7
## 10-1 临时表1 GVEY2ZC7
create table if not exists director_movie_single_temp
SELECT mda.ImdbId
     , mda.chineseTitle
     , mda.ImdbTitle
     , substring_index(substring_index(mda.director, ';', b.help_topic_id + 1), ';', - 1) AS director
FROM movies_director_audited mda
         INNER JOIN mysql.help_topic b
                    ON b.help_topic_id < (length(mda.director) - length(REPLACE(mda.director, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y');

## 10-2 查询 GVEY2ZC7
select publish_year_imdb, director_list.director, count(*) number
from director_movie_single_temp director_list,
     movies_publish_date_audited
where director_list.ImdbId = movies_publish_date_audited.ImdbId
group by publish_year_imdb, director
order by publish_year_imdb, number;

## 10-3 删除临时表 GVEY2ZC7
drop table if exists director_movie_single_temp;
#---------------------------------------------------------------------------------------------------------------------#

# 11. 重点导演电影对应关系列表 GK8XTTEG
## 11-1 临时表1 全部导演与电影对应关系 GK8XTTEG
create table if not exists director_movie_single_temp
SELECT mda.ImdbId
     , mda.chineseTitle
     , mda.ImdbTitle
     , substring_index(substring_index(mda.director, ';', b.help_topic_id + 1), ';',
                       - 1) AS director
FROM movies_director_audited mda
         INNER JOIN mysql.help_topic b
                    ON b.help_topic_id <
                       (length(mda.director) - length(REPLACE(mda.director, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y');

## 11-2 临时表2 重点导演名单 GK8XTTEG
create table if not exists important_directors_temp
select director_movie_single_temp.director, count(*) number
from director_movie_single_temp
group by director
order by number desc
LIMIT 38;

## 11-3 查询 GK8XTTEG
SELECT ImdbId
     , chineseTitle
     , ImdbTitle
     , director
FROM director_movie_single_temp
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y')
  and director in (select director
                   from important_directors_temp c);

## 11-4 删除临时表 GK8XTTEG
drop table if exists important_directors_temp;
drop table if exists director_movie_single_temp;
#---------------------------------------------------------------------------------------------------------------------#

# 12. 重点导演按年份电影数量S43SYH3G
## 12-1 临时表1 全部导演与电影对应关系 S43SYH3G
create table if not exists director_movie_single_temp
SELECT mda.ImdbId
     , mda.chineseTitle
     , mda.ImdbTitle
     , substring_index(substring_index(mda.director, ';', b.help_topic_id + 1),
                       ';',
                       - 1) AS director
FROM movies_director_audited mda
         INNER JOIN mysql.help_topic b
                    ON b.help_topic_id <
                       (length(mda.director) - length(REPLACE(mda.director, ';', '')) + 1)
where ImdbId in
      (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y');

## 12-2 临时表2 重点导演名单 S43SYH3G
create table if not exists important_directors_temp
select director_movie_single_temp.director, count(*) number
from director_movie_single_temp
group by director
order by number desc
LIMIT 38;

## 12-3 临时表3 重点导演电影对应关系 S43SYH3G
create table if not exists important_director_movie_single_temp
SELECT ImdbId
     , chineseTitle
     , ImdbTitle
     , director
FROM director_movie_single_temp
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y')
  and director in (select director
                   from important_directors_temp);
## 12-4 查询结果 S43SYH3G
select publish_year_imdb, director, count(*) number
from important_director_movie_single_temp,
     movies_publish_date_audited
where important_director_movie_single_temp.ImdbId = movies_publish_date_audited.ImdbId
group by publish_year_imdb, director
order by publish_year_imdb, number;

## 12-5 删除临时表 S43SYH3G
drop table if exists important_director_movie_single_temp;
drop table if exists important_directors_temp;
drop table if exists director_movie_single_temp;
#---------------------------------------------------------------------------------------------------------------------#

# 13. 重点导演电影数量 SL3BVS5Q

## 13-1 临时表1 SL3BVS5Q
create table if not exists director_movie_single_temp
SELECT mda.ImdbId
     , mda.chineseTitle
     , mda.ImdbTitle
     , substring_index(substring_index(mda.director, ';', b.help_topic_id + 1), ';', - 1) AS director
FROM movies_director_audited mda
         INNER JOIN mysql.help_topic b
                    ON b.help_topic_id < (length(mda.director) - length(REPLACE(mda.director, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y');

## 13-2 临时表2 SL3BVS5Q
create table if not exists important_directors_temp
select director, count(*) number
from director_movie_single_temp
group by director
order by number desc
LIMIT 38;

## 13-3 查询 SL3BVS5Q
select *
from important_directors_temp
order by number;

## 13-4 删除临时表 SL3BVS5Q
drop table if exists important_directors_temp;
drop table if exists director_movie_single_temp;
#---------------------------------------------------------------------------------------------------------------------#

# 14. 主要电影演员数量 5GSVD56U

## 14-1 临时表1 5GSVD56U
create table if not exists actor_movie_single_temp
SELECT maa.ImdbId
     , maa.chineseTitle
     , maa.ImdbTitle
     , substring_index(substring_index(maa.actor, ';', auto_id.id + 1), ';', - 1) AS actor
FROM movies_actor_audited maa
         JOIN auto_id
              ON auto_id.id < (length(maa.actor) - length(REPLACE(maa.actor, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y');
## 14-2 临时表2 5GSVD56U
create table if not exists important_actor_temp
select actor_movie_single_temp.actor, count(*) number
from actor_movie_single_temp
group by actor
order by number desc
limit 27;

## 14-3 查询 5GSVD56U
select *
from important_actor_temp
order by number;

## 14-4 删除临时表 5GSVD56U
drop table if exists actor_movie_single_temp;
drop table if exists important_actor_temp;
#---------------------------------------------------------------------------------------------------------------------#

# 15. 各类型电影数量 imdb数据 W8QGZ9A8
## 15-1 临时表 W8QGZ9A8
create table if not exists genre_single_temp
SELECT mga.ImdbId
     , mga.chineseTitle
     , mga.ImdbTitle
     , substring_index(substring_index(mga.imdbGenre, ',', b.help_topic_id + 1), ',', - 1) AS genre
FROM movie_genre_audited mga
         INNER JOIN mysql.help_topic b
                    ON b.help_topic_id < (length(mga.imdbGenre) - length(REPLACE(mga.imdbGenre, ',', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y');

## 15-2 查询 W8QGZ9A8
select genreBilingual, count(*) number
from genre_single_temp,genre_conversion
where genre_single_temp.genre=genre_conversion.genreEng
group by genreBilingual
order by number desc;

## 15-3 删除临时表 W8QGZ9A8
drop table if exists genre_single_temp;

#---------------------------------------------------------------------------------------------------------------------#
# 16. 各类型电影数量 豆瓣数据 LNVJSDBG
## 16-1 临时表 LNVJSDBG
create table if not exists genre_single_temp
SELECT mga.ImdbId
     , mga.chineseTitle
     , mga.ImdbTitle
     , substring_index(substring_index(mga.doubanGenre, ';', b.help_topic_id + 1), ';', - 1) AS genre
FROM movie_genre_audited mga
         INNER JOIN mysql.help_topic b
                    ON b.help_topic_id < (length(mga.doubanGenre) - length(REPLACE(mga.doubanGenre, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y');

## 16-2 查询 LNVJSDBG
select genre_single_temp.genre, count(*) number
from genre_single_temp
group by genre
order by number desc;

## 16-3 删除临时表 LNVJSDBG
drop table if exists genre_single_temp;