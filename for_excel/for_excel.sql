# 中文表 9UVGU5QQ
select * from movie_basic_info
left join movie_info_chinese_audited mica on movie_basic_info.ImdbId = mica.ImdbId
left join movie_language_audited mla on mica.ImdbId = mla.ImdbId;


# 语言种类表 BDX8SRX9
select * from (select originalLanguage from tmdb_movie_chinese group by originalLanguage) as languageCodeTable
left join language_conversion on languageCodeTable.originalLanguage=language_conversion.languageCode;
