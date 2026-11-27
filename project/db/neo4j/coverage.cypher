MATCH (s:Site {id:$id})
OPTIONAL MATCH (s)-[:NEAR]-(n:Site)
WITH s, collect(DISTINCT n) AS nearby
UNWIND [s]+nearby AS candidate
MATCH (g:Guide)-[:COVERS]->(candidate)
RETURN g.id AS id,g.name AS name,count(DISTINCT candidate) AS covered
ORDER BY covered DESC,id
