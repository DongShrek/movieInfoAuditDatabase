# 创建演员表
create table movies_actor_audited
select ImdbId, chineseTitle, ImdbTitle,actor
from imdb_douban_movie;

alter table movies_actor_audited
    add primary key (ImdbId(255));

## 未来更新策略：电影有增加则表更新
insert ignore into movies_actor_audited (ImdbId, chineseTitle, ImdbTitle,actor)
select ImdbId, chineseTitle, ImdbTitle, actor
from imdb_douban_movie;

# 用tmdb名字更新电影名
update movies_actor_audited a
set a.chineseTitle=(select t.movieTitle
                    from tmdb_movie_chinese t
                    where t.ImdbId = a.ImdbId)
where a.chineseTitle is null;