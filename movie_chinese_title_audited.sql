# 创建电影中文表
create table movie_chinese_title_audited
select m.ImdbId, m.chineseTitle
from imdb_douban_movie m;

alter table movie_chinese_title_audited
    add primary key (ImdbId(255));

## 未来更新策略：电影中文有增加则表更新
insert ignore into movie_chinese_title_audited (ImdbId, chineseTitle)
select m.ImdbId, m.chineseTitle
from imdb_douban_movie m;

## 利用TMDB更新缺失的中文名
insert ignore into movie_chinese_title_audited (ImdbId, chineseTitle)
select m.ImdbId, t.movieTitle
from imdb_douban_movie m,
     tmdb_movie_chinese t
where m.ImdbId = t.ImdbId
  and m.chineseTitle is null;
