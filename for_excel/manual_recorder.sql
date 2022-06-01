# 手工修改的数据库部分

# 只分析2022年以前的电影
update movies_analysis_list set isNeedAnalysis='n'
where ImdbId in (select ImdbId from movie_basic_info where Imdb250Day>'2021-12-31');

# 只分析类型为电影的影片
update movies_analysis_list set isNeedAnalysis='n'
where ImdbId in (select ImdbId from movie_basic_info where kind<>'movie');

# 排除电影教父合集The Godfather Trilogy: 1901-1980
update movies_analysis_list set isNeedAnalysis='n' where ImdbId='tt0150742';