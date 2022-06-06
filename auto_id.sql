# id辅助表 用于演员统计表一行变多行生成，只统计一部电影前5个演员
create table auto_id
(
    id int null
);

insert into auto_id(id) value (1);
insert into auto_id(id) value (2);
insert into auto_id(id) value (3);
insert into auto_id(id) value (4);
insert into auto_id(id) value (5);