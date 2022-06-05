# 手工修改的数据库部分

## （1）修改movies_analysis_list 表
# 只分析2022年以前的电影
update movies_analysis_list set isNeedAnalysis='n'
where ImdbId in (select ImdbId from movie_basic_info where Imdb250Day>'2021-12-31');

# 只分析类型为电影的影片
update movies_analysis_list set isNeedAnalysis='n'
where ImdbId in (select ImdbId from movie_basic_info where kind<>'movie');

# 排除电影教父合集The Godfather Trilogy: 1901-1980
update movies_analysis_list set isNeedAnalysis='n' where ImdbId='tt0150742';

# 剩余电影更新为y（需要分析）
update movies_analysis_list set isNeedAnalysis='y' where isNeedAnalysis is null ;

## （2）修改导演表
update movies_director_audited set director='詹姆斯·麦克提格 James McTeigue' where ImdbId='tt0434409'; #V字仇杀队
update movies_director_audited set director='特雷·帕克 Trey Parker' where ImdbId='tt0158983'; #南方公园：加长未删减剧场版
update movies_director_audited set director='萨维奇·史蒂夫·霍兰德 Savage Steve Holland' where ImdbId='tt0088794';
update movies_director_audited set director='苏达·孔加拉 Sudha Kongara' where ImdbId='tt10189514';
update movies_director_audited set director='穆拉特·丹达尔 Murat Dundar' where ImdbId='tt2592910';
update movies_director_audited set director='普雷姆·库玛 C. Prem Kumar' where ImdbId='tt7019842';
update movies_director_audited set director='拉姆·库玛 Ram Kumar' where ImdbId='tt7060344';
update movies_director_audited set director='埃泰勒姆·埃吉尔梅斯 Ertem Egilmez' where director='Ertem Egilmez Ertem Egilmez';