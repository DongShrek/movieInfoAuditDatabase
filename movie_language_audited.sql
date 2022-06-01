# 创建初始表
create table movie_language_audited (select tm.ImdbId, la.languageInChinese, tm.originalLanguage
                                     from tmdb_movie_chinese as tm
                                              left join (select *
                                                         from (select originalLanguage
                                                               from tmdb_movie_chinese
                                                               group by originalLanguage) as lu
                                                                  left join language_conversion on lu.originalLanguage = languageCode) as la
                                                        on la.languageCode = tm.originalLanguage);

alter table movie_language_audited
    add primary key (ImdbId(255));

# 更新策略
insert ignore into movie_language_audited(ImdbId, languageInChinese, originalLanguage)
select tm.ImdbId, la.languageInChinese, tm.originalLanguage
      from tmdb_movie_chinese as tm
               left join (select *
                          from (select originalLanguage
                                from tmdb_movie_chinese
                                group by originalLanguage) as lu
                                   left join language_conversion on lu.originalLanguage = languageCode) as la
                         on la.languageCode = tm.originalLanguage
where ImdbId not in (select ImdbId from movie_language_audited)