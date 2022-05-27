# 语言占比统计饼图_3FQHYAW2
select mla.chineseName as languages, count(mla.chineseName) as number
from movies_analysis_list mal,
     movie_language_audited mla
where mal.ImdbId = mla.ImdbId
group by mla.chineseName order by number desc