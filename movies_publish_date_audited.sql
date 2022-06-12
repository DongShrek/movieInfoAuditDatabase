# 创建电影日期表
create table movies_publish_date_audited
select m.ImdbId,m.Title ImdbTitle,i.chineseTitle,m.Year publish_year_imdb,i.year publish_year_douban,i.pubdates publish_date from movie_basic_info m
left join imdb_douban_movie i on m.ImdbId=i.ImdbId;

alter table movies_publish_date_audited
    add primary key (ImdbId(255));

## 未来更新策略：电影有增加则表更新
insert ignore into movies_publish_date_audited (ImdbId,ImdbTitle,chineseTitle,publish_year_imdb,publish_year_douban,publish_date)
select m.ImdbId,m.Title,i.chineseTitle,m.Year,i.year,i.pubdates from movie_basic_info m
left join imdb_douban_movie i on m.ImdbId=i.ImdbId;

# 用tmdb名字更新电影名
update movies_publish_date_audited a
set a.chineseTitle=(select t.movieTitle
                    from tmdb_movie_chinese t
                    where t.ImdbId = a.ImdbId)
where a.chineseTitle is null;