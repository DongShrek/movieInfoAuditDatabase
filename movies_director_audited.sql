# 导演原始表
create table movies_director_audited
select ImdbId, chineseTitle, ImdbTitle, director
from imdb_douban_movie;
