# imdb榜单日表，imdb_250_day_list
create table imdb_250_day_list select day,row_number() over () as serialNumber  from imdb_history group by day order by day;