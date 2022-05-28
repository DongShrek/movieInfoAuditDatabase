# 语言占比统计饼图_3FQHYAW2
select mla.languageInChinese as languages, count(mla.languageInChinese) as number
from movies_analysis_list mal,
     movie_language_audited mla
where mal.ImdbId = mla.ImdbId
group by mla.languageInChinese order by number desc