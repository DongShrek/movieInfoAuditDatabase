# 中文表 9UVGU5QQ
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
where a.ImdbId = movies_analysis_list.ImdbId and movies_analysis_list.isNeedAnalysis='y';

# 语言种类表 BDX8SRX9
select *
from (select originalLanguage
      from tmdb_movie_chinese,
           movies_analysis_list
      where tmdb_movie_chinese.ImdbId = movies_analysis_list.ImdbId and movies_analysis_list.isNeedAnalysis='y'
      group by originalLanguage) as languageCodeTable
         left join language_conversion on languageCodeTable.originalLanguage = language_conversion.languageCode;


# 在榜时间表 9X3KC8SR
select *
from (select ImdbId,
             movieTitle,
             startDay,
             startDayNumber,
             endDay,
             endDayNumber,
             dayCount,
             (endDayNumber - startDayNumber + 1)            duration,
             (endDayNumber - startDayNumber + 1 - dayCount) difference
      from (select startEndDayTable.ImdbId   ImdbId,
                   startEndDayTable.Title    movieTitle,
                   startEndDayTable.startDay startDay,
                   daylist1.serialNumber     startDayNumber,
                   startEndDayTable.endDay   endDay,
                   daylist2.serialNumber     endDayNumber,
                   startEndDayTable.dayCount
            from (select ImdbId, Title, min(day) startDay, max(day) endDay, count(day) dayCount
                  from imdb_history
                  where day < '2022-01-01'
                  group by ImdbId, Title) as startEndDayTable
                     left join imdb_250_day_list as daylist1 on startday = daylist1.day
                     left join imdb_250_day_list as daylist2 on endday = daylist2.day) as movieDuration) a,
     movies_analysis_list
where a.ImdbId = movies_analysis_list.ImdbId and movies_analysis_list.isNeedAnalysis='y'
order by a.endDay desc, a.startDay;

# 生成导演表 单行变多行 JSLA2ZY8
SELECT mda.ImdbId
     , mda.chineseTitle
     , mda.ImdbTitle
     , substring_index(substring_index(mda.director, ';', b.help_topic_id + 1), ';', - 1) AS director
FROM movies_director_audited mda
         INNER JOIN mysql.help_topic b
                    ON b.help_topic_id < (length(mda.director) - length(REPLACE(mda.director, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis='y');

# 电影导演电影数量 SPHW52XE
select a.director ,count(*) number from (SELECT mda.ImdbId
     , mda.chineseTitle
     , mda.ImdbTitle
     , substring_index(substring_index(mda.director, ';', b.help_topic_id + 1), ';', - 1) AS director
FROM movies_director_audited mda
         INNER JOIN mysql.help_topic b
                    ON b.help_topic_id < (length(mda.director) - length(REPLACE(mda.director, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis='y')) a group by director order by number desc ;

# 各语言数量 语言占比统计饼图_3FQHYAW2
select mla.languageInChinese as languages, count(mla.languageInChinese) as number
from movies_analysis_list mal,
     movie_language_audited mla
where mal.ImdbId = mla.ImdbId and mal.isNeedAnalysis='y'
group by mla.languageInChinese order by number desc

# 生成演员表 单行变多行 Z77MAPS2
SELECT maa.ImdbId
     , maa.chineseTitle
     , maa.ImdbTitle
     , substring_index(substring_index(maa.actor, ';', auto_id.id + 1), ';', - 1) AS actor
FROM movies_actor_audited maa
JOIN auto_id
ON auto_id.id< (length(maa.actor) - length(REPLACE(maa.actor, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis='y')

# 演员电影数量 3DHCJBWY 取一部电影前5位的演员
select a.actor ,count(*) number from
(SELECT maa.ImdbId
     , maa.chineseTitle
     , maa.ImdbTitle
     , substring_index(substring_index(maa.actor, ';', auto_id.id + 1), ';', - 1) AS actor
FROM movies_actor_audited maa
JOIN auto_id
ON auto_id.id< (length(maa.actor) - length(REPLACE(maa.actor, ';', '')) + 1)
where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis='y')) a group by actor order by number desc ;

# 电影日期 X8TJAGBA
select timeline_year.the_year year, ifnull(a.number, 0) number
from timeline_year
         left join (select publish_year, count(*) number
                    from (select *
                          from movies_publish_date_audited
                          where ImdbId in (select ImdbId from movies_analysis_list where isNeedAnalysis = 'y')) md
                    group by publish_year
                    order by publish_year) a on timeline_year.the_year = a.publish_year