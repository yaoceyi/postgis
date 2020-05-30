
-- select admin,ST_NPoints(geom)as num,ST_MemSize(geom) as mem_size 
-- from ne_10m_admin_0_countries order by num;

-- select admin,ST_MemSize(geom) as mem_size  
-- from ne_10m_admin_0_countries_subdivided
-- where ST_MemSize(geom)>8192 order by mem_size;


--    select c.admin from ne_10m_admin_0_countries c 
--    join ne_10m_populated_places_simple p
--    on ST_Contains(c.geom,p.geom);

--  CREATE TABLE ne_10m_admin_0_countries_subdivided AS
--  SELECT admin, ST_Subdivide(geom,100) AS geom
--  FROM ne_10m_admin_0_countries;