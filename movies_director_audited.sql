# 导演原始表
create table movies_director_audited
select ImdbId, chineseTitle, ImdbTitle, director
from imdb_douban_movie;

# 用tmdb名字更新电影名
update movies_director_audited a
set a.chineseTitle=(select t.movieTitle
                    from tmdb_movie_chinese t
                    where t.ImdbId = a.ImdbId)
where a.chineseTitle is null;