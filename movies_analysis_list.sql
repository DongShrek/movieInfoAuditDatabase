# 需要分析的电影清单
create table movies_analysis_list select ImdbId,Title from movie_basic_info

# 是否属于需要分析的电影
alter table movies_analysis_list
    add isNeedAnalysis text null;