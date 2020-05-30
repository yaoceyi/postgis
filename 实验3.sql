--生成target表，然后也要单独抽离出岛屿的shp文件。不要一次运行所有的函数！！！
create table public.target("id" SERIAL not null,"target" character varying(80));
insert into target("target") select tag_id from albatross_dd_pro group by tag_id;
------------------------------------------------------------------------------------------
  drop function if exists maxV(text);
  create or replace function maxV(target text)
  --返回的数据area为面积，path为路径，maxv为最大瞬时速度，leng为路径长度，tagr为鸟的id
    returns table("area" geometry,"path" geometry,"maxv" float,"leng" float,"tagr" character varying(80)) as $body$
  begin
  return query
  	with recursive next_length as(
    (
     select 
     geom,array[id] as idlist,tag_id,
     sqrt(0) len,timestamp,age(timestamp::timestamp,timestamp::timestamp) dtime --两点间的时间间隔
     from albatross_dd_pro d
     where timestamp=(select min(timestamp) from albatross_dd_pro where tag_id=target)
     )
   	 union all
     (
    	select 
    	a.geom,array_append(n.idlist,a.id) as idlist,a.tag_id,st_distance(n.geom,a.geom) len,a.timestamp,age(a.timestamp::timestamp,n.timestamp::timestamp) dtime
    	from albatross_dd_pro a,next_length n 
    	where strpos(a.tag_id,target)<>0
   	    and not n.idlist @> array[a.id]
		order by dtime asc limit 1
   	 )	
     )
    select ST_ConvexHull(st_makeline(geom)) as area,st_makeline(geom) as path,
	max(len/(EXTRACT(HOUR from to_char(dtime,'HH12:MI:SS')::interval)*60+EXTRACT(MINUTE from to_char(dtime,'HH12:MI:SS')::interval))) as maxv,--计算两点间的瞬时速度
	sum(len) as leng ,tag_id as tagr from next_length 
    where (EXTRACT(HOUR from to_char(dtime,'HH12:MI:SS')::interval)*60+EXTRACT(MINUTE from to_char(dtime,'HH12:MI:SS')::interval))<>0 --把时间间隔为0的去掉
	group by tag_id;
  end;
  $body$
  language plpgsql VOLATILE COST 10 ROWS 10 strict;
 --测试maxV
 --select * from maxV('unbanded-156');
 
 
 
 ------------------------------
 --如果已经存f函数，删除
 drop function if exists f();
 --重新创建
 create or replace function f()
 	--返回的数据area1为面积，path1为路径，maxv1为最大瞬时速度，leng1为路径长度，tag为鸟的id
     returns table("area1" geometry, "path1" geometry,"maxv1" float,"leng1" float,"tag" character varying(80))
 as
 $$
 declare
 begin
 	-- 遍历target表，遍历所有的鸟，并且调用maxV函数
    for num in 1..23 loop
	  return query
  		select area as area1,path as path1,maxv as maxv1, leng as leng1,tagr as tag from 
		 maxV((select target from target where id=num));--调用maxV函数
        end loop;
 end;
 $$ language plpgsql COST 10 ROWS 10;
 --把数据放到表中
create table bird as (select f.area1,f.path1,f.maxv1,f.leng1,f.tag from f());
----------------------------------------------------------------------------------------

--如果已经存dao1函数，删除
drop function if exists dao1(text);
--重新创建
create or replace function dao1(target text)
--返回一张表
     returns table("dao" geometry,"tag" character varying(80)) as $$
declare
begin
  return query
       with points1 as(
        select p.geom,p.tag_id from 
        	dao1,albatross_dd_pro p join land_lambert l 
        	on ST_DWithin(p.geom,l.geom,100*1000) --创建缓冲区 
       	where ST_DWithin(p.geom,dao1.geom,100*1000)--判断点是否在缓冲区内
        	and strpos(p.tag_id,target)<>0
     )
   -- 把所有在缓冲区内的点变成一个多边形，然后放到表内
   select ST_ConvexHull(st_makeline(points1.geom))as dao,tag_id as tag from points1 group by tag_id;
   end;
  $$
 language plpgsql strict;
-------------
drop function if exists fun();
 create or replace function fun()
     returns table("dao1" geometry,"tag1" character varying(80))
 as
 $$
 declare
 begin
 	-- 遍历target表，遍历所有的鸟
    for num in 1..23 loop
	  return query
  		select  dao as dao1,tag as tag1 from dao1((select target from target where id=num));
        end loop;
 end;
 $$ language plpgsql COST 10 ROWS 10;
--把数据存储道daoarea表里面
 create table daoarea as (select fun.dao1,fun.tag1 from fun());


