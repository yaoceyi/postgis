--  create table flood_build as(SELECT val, geom As geomwkt
--  FROM (
--  SELECT dp.*
--  FROM dem, LATERAL ST_DumpAsPolygons(rast) AS dp
--  ) As foo
--  WHERE val BETWEEN 0 and 30
--  ORDER BY val asc);

 create table flood_build_union as (
 	select St_Union(geomwkt) from flood_build
 );
