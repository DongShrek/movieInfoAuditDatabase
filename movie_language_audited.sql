create table movie_language_audited (select tm.ImdbId, la.languageInChinese, tm.originalLanguage
                                     from tmdb_movie_chinese as tm
                                              left join (select *
                                                         from (select originalLanguage
                                                               from tmdb_movie_chinese
                                                               group by originalLanguage) as lu
                                                                  left join language_conversion on lu.originalLanguage = languageCode) as la
                                                        on la.languageCode = tm.originalLanguage);
