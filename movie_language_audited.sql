# 创建初始表
create table movie_language_audited
select tm.ImdbId, language_conversion.languageInChinese, tm.originalLanguage
from tmdb_movie_chinese as tm
left join language_conversion
on language_conversion.languageCode = tm.originalLanguage;

alter table movie_language_audited
    add primary key (ImdbId(255));

# 更新策略
insert ignore into movie_language_audited(ImdbId, languageInChinese, originalLanguage)
select tm.ImdbId, language_conversion.languageInChinese, tm.originalLanguage
from tmdb_movie_chinese as tm
left join language_conversion
on language_conversion.languageCode = tm.originalLanguage;