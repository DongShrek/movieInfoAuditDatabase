# imdb榜单日表，imdb_250_day_list
create table imdb_250_day_list select day,row_number() over () as serialNumber  from imdb_history group by day order by day;
alter table imdb_250_day_list add primary key (day(255));

# 更新策略
replace into imdb_250_day_list (day, serialNumber) select day,row_number() over () as serialNumber  from imdb_history group by day order by day;

# 显示未更新的日期
select daylist.Day,daylist.serialNumber from (select day,row_number() over () as serialNumber  from imdb_history group by day order by day) as daylist
where day not in(select day from imdb_250_day_list);
