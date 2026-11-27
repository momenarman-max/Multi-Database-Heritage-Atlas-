MATCH (me:Visitor {id:$id}),(peer:Visitor)-[:VISITED]->(s:Site)
WHERE peer <> me AND any(tag IN me.interests WHERE tag IN peer.interests)
AND NOT EXISTS { MATCH (me)-[:VISITED]->(s) }
RETURN s.id AS id,s.name AS name,count(DISTINCT peer) AS peers
ORDER BY peers DESC,id
