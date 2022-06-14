# 一直在榜影片(临时表，为计算快速暂时保留，更新需重新生成)
## 临时表1
create table if not exists start_end_day_temp
select ImdbId, Title, min(day) startDay, max(day) endDay, count(day) dayCount
from imdb_history
where day < '2022-01-01'
group by ImdbId, Title;
## 临时表2
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

## 临时表3
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

# 创建一直在榜影片列表
create table if not exists always_on_list_movie_temporary_buff
select movies_analysis_list.ImdbId,
       movies_analysis_list.Title,
       movie_duration_temp.startDay,
       movie_duration_temp.endDay,
       movie_duration_temp.dayCount,
       movie_duration_temp.duration
from movie_duration_temp,
     movies_analysis_list
where movie_duration_temp.ImdbId = movies_analysis_list.ImdbId
  and movies_analysis_list.isNeedAnalysis = 'y'
  and difference = 0
  and endDay = '2021-12-31'
order by movie_duration_temp.endDay desc, movie_duration_temp.startDay;

drop table if exists movie_duration_temp;
drop table if exists start_end_day_serial_number_temp;
drop table if exists start_end_day_temp;