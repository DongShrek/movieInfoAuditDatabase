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
     movies_analysis_list,
     movie_chinese_title_audited
where movie_duration_temp.ImdbId = movies_analysis_list.ImdbId
  and movie_chinese_title_audited.ImdbId=movie_duration_temp.ImdbId
  and movies_analysis_list.isNeedAnalysis = 'y'
order by dayCount desc;

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
# 1006. 一直在榜 语言占比统计饼图 BJL55MDD
select mla.languageInChinese as languages, count(mla.languageInChinese) as number
from movies_analysis_list mal,
     movie_language_audited mla,
     always_on_list_movie_temporary_buff alw
where mal.ImdbId = mla.ImdbId
  and mal.isNeedAnalysis = 'y'
  and mal.ImdbId = alw.ImdbId
group by mla.languageInChinese
order by number desc
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

## 9-2 查询 X8TJAGBA
select publish_year_imdb, count(*) number
from movie_publish_year_temp
group by publish_year_imdb
order by publish_year_imdb;

## 9-3 删除临时表 X8TJAGBA
drop table if exists movie_publish_year_temp;
#---------------------------------------------------------------------------------------------------------------------#

# 1009 一直在榜影片每年电影数量 电影与年对应关系 TLC5RHTW

## 1009-1 临时表1 仅临时表1 movie_publish_year_temp 与 X8TJAGBA不同

create table if not exists movie_publish_year_temp
select *
from movies_publish_date_audited
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y') and ImdbId in (select ImdbId from always_on_list_movie_temporary_buff);

# 比较未一直在榜的影片
create table if not exists movie_publish_year_temp
select *
from movies_publish_date_audited
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y') and ImdbId not in (select ImdbId from always_on_list_movie_temporary_buff);
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

# 11. **重点导演**电影对应关系列表 GK8XTTEG
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

# 1011. 一直在榜**重点导演**电影对应关系列表 8J5BW4J9 导演选取有两部以上的导演
## 1011-1 临时表1  一直在榜影片的导演与电影对应关系 8J5BW4J9
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
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y') and ImdbId in (select ImdbId from always_on_list_movie_temporary_buff);

## 1011-2 临时表2 一直在榜重点导演名单 8J5BW4J9
create table if not exists important_directors_temp
select director_movie_single_temp.director, count(*) number
from director_movie_single_temp
group by director
order by number desc
LIMIT 33;

## 1011-3 查询一直在榜 一直在榜重点导演与电影对应关系 8J5BW4J9
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
# 2012 导演创作时段时间轴甘特图 PX6FL6GN
select director, min(publish_year_imdb) startYear,max(publish_year_imdb) endYear,max(publish_year_imdb)-min(publish_year_imdb) period
from important_director_movie_single_temp,
     movies_publish_date_audited
where important_director_movie_single_temp.ImdbId = movies_publish_date_audited.ImdbId
group by director
order by startYear

#----------------------------------------------------------------------------------------------------------------------#
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

# 1013. **重点导演**电影数量 PRLVY7G3 两部以上影片导演

## 1013-1 临时表1 PRLVY7G3
create table if not exists director_movie_single_temp
SELECT mda.ImdbId
     , mda.chineseTitle
     , mda.ImdbTitle
     , substring_index(substring_index(mda.director, ';', b.help_topic_id + 1), ';', - 1) AS director
FROM movies_director_audited mda
         INNER JOIN mysql.help_topic b
                    ON b.help_topic_id < (length(mda.director) - length(REPLACE(mda.director, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y') and ImdbId in (select ImdbId from always_on_list_movie_temporary_buff);

## 1013-2 临时表2 一直在榜重点导演的影片数量 PRLVY7G3
create table if not exists important_directors_temp
select director, count(*) number
from director_movie_single_temp
group by director
order by number desc
LIMIT 33;

## 1013-3 查询 PRLVY7G3 再排序
select *
from important_directors_temp
order by number;

## 1013-4 删除临时表 PRLVY7G3
drop table if exists important_directors_temp;
drop table if exists director_movie_single_temp;

#---------------------------------------------------------------------------------------------------------------------#
# 2013各数量电影数目所包括的导演数目 EMR2ABAA
select movieAmount, count(*) directorAmount
from (select director, count(*) movieAmount from director_movie_single_temp group by director) a
group by movieAmount
order by movieAmount desc
#----------------------------------------------------------------------------------------------------------------------#

# 14. 主要电影演员数量 5GSVD56U

# 14-0-1 id临时表

create table if not exists auto_id_temp
(
    id int null
);

# 14-0-2 创建存储过程 取前5位演员
create procedure myproc()
begin
    declare i int default 1;
    while i <= 5
        do
            insert into auto_id_temp (id) values (i);
            set i = i + 1;
        end while;
end;

# 14-0-3 调用过程
call myproc();

# 14-0-4 删除过程
drop procedure if exists myproc;

## 14-1 临时表1 5GSVD56U
create table if not exists actor_movie_single_temp
SELECT maa.ImdbId
     , maa.chineseTitle
     , maa.ImdbTitle
     , substring_index(substring_index(maa.actor, ';', auto_id_temp.id + 1), ';', - 1) AS actor
FROM movies_actor_audited maa
         JOIN auto_id_temp
              ON auto_id_temp.id < (length(maa.actor) - length(REPLACE(maa.actor, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y');
## 14-2 临时表2 5GSVD56U
create table if not exists important_actor_temp
select actor_movie_single_temp.actor, count(*) number
from actor_movie_single_temp
group by actor
order by number desc;

## 14-3 查询 5GSVD56U 参演影片大于5
select *
from important_actor_temp
where number>5
order by number;

## 14-4 删除临时表 5GSVD56U
drop table if exists actor_movie_single_temp;
drop table if exists important_actor_temp;
drop table if exists auto_id_temp;
#---------------------------------------------------------------------------------------------------------------------#

# 1014 一直在榜影片演员参演影片数量表 A95BJJ3R
# 仅临时表1 actor_movie_single_temp和查询与5GSVD56U不同
create table if not exists actor_movie_single_temp
SELECT maa.ImdbId
     , maa.chineseTitle
     , maa.ImdbTitle
     , substring_index(substring_index(maa.actor, ';', auto_id_temp.id + 1), ';', - 1) AS actor
FROM movies_actor_audited maa
         JOIN auto_id_temp
              ON auto_id_temp.id < (length(maa.actor) - length(REPLACE(maa.actor, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y') and ImdbId in (select ImdbId from always_on_list_movie_temporary_buff);

## 1014-3 查询 5GSVD56U 参演影片大于2
select *
from important_actor_temp
where number>2
order by number;


#---------------------------------------------------------------------------------------------------------------------#

# 2014 前两位主要演员表 U5M667VN
# 仅存储过程与查询5GSVD56U不同
# 14-0-2 创建存储过程 取前两位演员

create procedure myproc()
begin
    declare i int default 1;
    while i <= 2
        do
            insert into auto_id_temp (id) values (i);
            set i = i + 1;
        end while;
end

## 14-3 查询 5GSVD56U 参演影片大于3

select *
from important_actor_temp
where number>3
order by number;


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
# 1015 一直在榜影片 影片类型 按照imdb统计 GZ6X9PL5
# 仅临时表genre_single_temp不同 GZ6X9PL5
create table if not exists genre_single_temp
SELECT mga.ImdbId
     , mga.chineseTitle
     , mga.ImdbTitle
     , substring_index(substring_index(mga.imdbGenre, ',', b.help_topic_id + 1), ',', - 1) AS genre
FROM movie_genre_audited mga
         INNER JOIN mysql.help_topic b
                    ON b.help_topic_id < (length(mga.imdbGenre) - length(REPLACE(mga.imdbGenre, ',', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y') and ImdbId in (select ImdbId from always_on_list_movie_temporary_buff);;


# 比较未一直在榜的影片
create table if not exists genre_single_temp
SELECT mga.ImdbId
     , mga.chineseTitle
     , mga.ImdbTitle
     , substring_index(substring_index(mga.imdbGenre, ',', b.help_topic_id + 1), ',', - 1) AS genre
FROM movie_genre_audited mga
         INNER JOIN mysql.help_topic b
                    ON b.help_topic_id < (length(mga.imdbGenre) - length(REPLACE(mga.imdbGenre, ',', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y') and ImdbId not in (select ImdbId from always_on_list_movie_temporary_buff);;


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

#---------------------------------------------------------------------------------------------------------------------#
# 17. 在榜时间与电影出版日期关系 UDDH8EUC
## 17-1 临时表1 UDDH8EUC
create table if not exists start_end_day_temp
select ImdbId, Title, min(day) startDay, max(day) endDay, count(day) dayCount
from imdb_history
where day < '2022-01-01'
group by ImdbId, Title;
## 17-2 临时表2 UDDH8EUC
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

## 17-3 临时表3 UDDH8EUC
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

## 17-4 查询 UDDH8EUC
select movie_duration_temp.ImdbId,
       concat(movie_chinese_title_audited.chineseTitle,' ',movies_publish_date_audited.publish_year_imdb) movieTitle,
       movie_duration_temp.dayCount,
       substring_index(movie_duration_temp.startDay, '-', 1) startListYear,
       substring_index(movie_duration_temp.endDay, '-', 1) endListYear,
       movies_publish_date_audited.publish_year_imdb
from movie_duration_temp,
     movies_analysis_list,
     movie_chinese_title_audited,
     movies_publish_date_audited
where movie_duration_temp.ImdbId = movies_analysis_list.ImdbId
  and movie_duration_temp.ImdbId = movie_chinese_title_audited.ImdbId
  and movie_duration_temp.ImdbId = movies_publish_date_audited.ImdbId
  and movies_analysis_list.isNeedAnalysis = 'y'
order by movies_publish_date_audited.publish_year_imdb,dayCount desc;

## 17-5 删除临时表 UDDH8EUC
drop table if exists movie_duration_temp;
drop table if exists start_end_day_serial_number_temp;
drop table if exists start_end_day_temp;

#---------------------------------------------------------------------------------------------------------------------#

## 18 曾上榜影片进入榜单按年统计数量 2LPRKAVT
select cast(Imdb250Year as SIGNED) Imdb250Year, count(*) number
from (select ImdbId, substring_index(Imdb250Day, '-', 1) Imdb250Year from movie_basic_info) a
where a.ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis='y')
group by Imdb250Year order by Imdb250Year;

#---------------------------------------------------------------------------------------------------------------------#
## 1018 一直在榜影片进入榜单按年统计数量 SWQ85YAT
select cast(Imdb250Year as SIGNED) Imdb250Year, count(*) number
from (select ImdbId, substring_index(Imdb250Day, '-', 1) Imdb250Year from movie_basic_info) a
where a.ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis='y') and a.ImdbId in (select ImdbId from always_on_list_movie_temporary_buff)
group by Imdb250Year order by Imdb250Year;

## 未一直在榜的影片
select cast(Imdb250Year as SIGNED) Imdb250Year, count(*) number
from (select ImdbId, substring_index(Imdb250Day, '-', 1) Imdb250Year from movie_basic_info) a
where a.ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis='y') and a.ImdbId not in (select ImdbId from always_on_list_movie_temporary_buff)
group by Imdb250Year order by Imdb250Year;

#---------------------------------------------------------------------------------------------------------------------#
# 19. 影片发行年与进入榜单年份关系 6PQ87SUJ
select count(*) Quantity,substring_index(a.Imdb250Day, '-', 1) Imdb250Year, b.publish_year_imdb
from movie_basic_info a,
     movies_publish_date_audited b
where a.ImdbId = b.ImdbId
  and a.ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y')
group by Imdb250Year, publish_year_imdb;
#---------------------------------------------------------------------------------------------------------------------#

#1019 # 一直在榜影片发行年与进入榜单年份关系 XC9BJ7HW
select count(*) Quantity, substring_index(a.Imdb250Day, '-', 1) Imdb250Year, b.publish_year_imdb
from movie_basic_info a,
     movies_publish_date_audited b
where a.ImdbId = b.ImdbId
  and a.ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y')
  and a.ImdbId in (select ImdbId from always_on_list_movie_temporary_buff)
group by Imdb250Year, publish_year_imdb;

#---------------------------------------------------------------------------------------------------------------------#
# 20. 影片发行年与进入榜单年与类型关系 C99LFKT3

# genre_single_temp 查看 15-1 临时表 W8QGZ9A8
create table if not exists movie_inlist_release_year_temp
select a.ImdbId,b.chineseTitle, substring_index(a.Imdb250Day, '-', 1) Imdb250Year, b.publish_year_imdb
from movie_basic_info a,
     movies_publish_date_audited b
where a.ImdbId = b.ImdbId
  and a.ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y');

select genre_single_temp.chineseTitle,
       movie_inlist_release_year_temp.publish_year_imdb,
       movie_inlist_rrelease_year_temp.Imdb250Year,
       genre_conversion.genreBilingual
from genre_single_temp
left join movie_inlist_release_year_temp on genre_single_temp.ImdbId=movie_inlist_release_year_temp.ImdbId
left join genre_conversion on genre_single_temp.genre=genre_conversion.genreEng;

drop table if exists movie_inlist_release_year_temp;

#---------------------------------------------------------------------------------------------------------------------#
# 21. 历史数据完整度 D8SCDL3T
select count(*) Quantity, substring_index(Day, '-', 1) onlistyear
from (select Day from imdb_history where Day < '2022-01-01' group by Day) a
group by onlistyear;

#----------------------------------------------------------------------------------------------------------------------#
# 22. 整体投票情况 按月份 EN2GNA2T

select
       substring_index(Day, '-', 2) month,
       sum(Votes)                   voteAmount
from imdb_history
where imdb_history.ImdbId in (select ImdbId from movies_analysis_list) and Day<'2022-01-01'
group by month

#----------------------------------------------------------------------------------------------------------------------#
# 23. 整体投票情况 按日 JTECRS33

select
       Day listDay,
       sum(Votes)                   voteAmount
from imdb_history
where imdb_history.ImdbId in (select ImdbId from movies_analysis_list) and Day<'2022-01-01'
group by listDay


#---------------------------------------------------------------------------------------------------------------------#
## 30 所有印度电影 CWXU2J6J
# 所有印度电影
select ImdbId, concat(chineseTitle, '(', publish_year_imdb, ')') fullTitle, publish_year_imdb release_year
from movies_publish_date_audited
where ImdbId in (select ImdbId
                 from movie_language_audited
                 where languageInChinese = '印度语')
  and ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y') order by release_year;

#---------------------------------------------------------------------------------------------------------------------#
## 31. 印度电影投票情况 QTACCUN7
# 31-1 临时表 所有印度电影 QTACCUN7
create table if not exists all_india_movie_temp
select ImdbId, concat(chineseTitle, '(', publish_year_imdb, ')') fullTitle, publish_year_imdb release_year
from movies_publish_date_audited
where ImdbId in (select ImdbId
                 from movie_language_audited
                 where languageInChinese = '印度语')
  and ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y')
order by release_year;

# 31-2 查询 QTACCUN7
select imdb_history.ImdbId,
       concat(movies_publish_date_audited.chineseTitle,' (',movies_publish_date_audited.publish_year_imdb,')') chineseTitle,
       substring_index(Day, '-', 2) month,
       sum(Votes)                   number,
       movies_publish_date_audited.publish_year_imdb releaseYear
from imdb_history
         left join movies_publish_date_audited on movies_publish_date_audited.ImdbId = imdb_history.ImdbId
where imdb_history.ImdbId in (select ImdbId from all_india_movie_temp) and Day<'2022-01-01'
group by month, imdb_history.ImdbId
order by releaseYear;

# 31-3 删除临时表 QTACCUN7
drop table if exists all_india_movie_temp
#---------------------------------------------------------------------------------------------------------------------#
# 32. 印度电影打分情况 QUECSJJC
select imdb_history.ImdbId,
       concat(movies_publish_date_audited.chineseTitle,' (',movies_publish_date_audited.publish_year_imdb,')') chineseTitle,
       substring_index(Day, '-', 2) month,
       round(avg(Rating),1)                  rating,
       movies_publish_date_audited.publish_year_imdb releaseYear
from imdb_history
         left join movies_publish_date_audited on movies_publish_date_audited.ImdbId = imdb_history.ImdbId
where imdb_history.ImdbId in (select ImdbId from all_india_movie_temp) and Day<'2022-01-01'
group by month, imdb_history.ImdbId
order by releaseYear;

#---------------------------------------------------------------------------------------------------------------------#
# 33.统计每个月有多少印度电影在榜 ZZ8M2YAZ
select count(ImdbId) MovieAmount,month from (select
       substring_index(Day, '-', 2) month,
       ImdbId
from imdb_history
where imdb_history.ImdbId in (select ImdbId from all_india_movie_temp) and Day<'2022-01-01'
group by month,ImdbId) a group by month
#---------------------------------------------------------------------------------------------------------------------#
# 34. 统计每天有多少印度电影在榜 VPPLAP2P
select
       date_format(Day,'%Y-%m-%d') listDay,
       count(*) amount
from imdb_history
where imdb_history.ImdbId in (select ImdbId from all_india_movie_temp) and Day<'2022-01-01'
group by listDay
