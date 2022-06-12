# 创建电影类型表
create table if not exists movie_genre_audited
select m.ImdbId,m.Title ImdbTitle,d.chineseTitle,m.Genre imdbGenre,d.genres doubanGenre from movie_basic_info m
left join imdb_douban_movie d on m.ImdbId=d.ImdbId;

alter table movie_genre_audited
    add primary key (ImdbId(255));

# 未来更新策略：电影有增加则表更新
insert ignore into movie_genre_audited (ImdbId,ImdbTitle,chineseTitle,imdbGenre,doubanGenre)
select m.ImdbId,m.Title ImdbTitle,d.chineseTitle,m.Genre imdbGenre,d.genres doubanGenre from movie_basic_info m
left join imdb_douban_movie d on m.ImdbId=d.ImdbId;

# 用tmdb名字更新电影名
update movie_genre_audited a
set a.chineseTitle=(select t.movieTitle
                    from tmdb_movie_chinese t
                    where t.ImdbId = a.ImdbId)
where a.chineseTitle is null;