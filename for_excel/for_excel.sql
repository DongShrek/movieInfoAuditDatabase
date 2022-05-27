# 中文表 9UVGU5QQ
select * from movie_basic_info
left join movie_info_chinese_audited mica on movie_basic_info.ImdbId = mica.ImdbId
left join movie_language_audited mla on mica.ImdbId = mla.ImdbId;


# 语言种类表 BDX8SRX9
select * from (select originalLanguage from tmdb_movie_chinese group by originalLanguage) as languageCodeTable
left join language_conversion on languageCodeTable.originalLanguage=language_conversion.languageCode;

# 在榜时间表 9X3KC8SR
select ImdbId,
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
            group by ImdbId, Title) as startEndDayTable
               left join imdb_250_day_list as daylist1 on startday = daylist1.day
               left join imdb_250_day_list as daylist2 on endday = daylist2.day) as movieDuration
order by movieDuration.endDay desc, movieDuration.startDay;
