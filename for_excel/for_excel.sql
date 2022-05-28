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
where a.ImdbId = movies_analysis_list.ImdbId;


# 语言种类表 BDX8SRX9
select *
from (select originalLanguage
      from tmdb_movie_chinese,
           movies_analysis_list
      where tmdb_movie_chinese.ImdbId = movies_analysis_list.ImdbId
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
where a.ImdbId = movies_analysis_list.ImdbId
order by a.endDay desc, a.startDay;
