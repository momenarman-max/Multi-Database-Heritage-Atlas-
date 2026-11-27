// One statement in Neo4j Browser. The temporary nodes are created and removed atomically.
CREATE (g:Guide {id:randomUUID(),name:'Test'}), (s:Site {id:randomUUID(),name:'Test site'})
CREATE (g)-[r:COVERS]->(s)
WITH g,r,s SET g.name='Updated',r.languages=['ar']
WITH g,r,s,g.name AS observed,r.languages AS languages
DELETE r,g,s RETURN observed,languages;
