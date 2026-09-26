-- Find all items matching the name (case-insensitive/partial), then recursively
-- walk each item's parents to the root. Build each path root → item, append the
-- item's date when present, and sort matching items newest → oldest (NULL dates last).
WITH RECURSIVE ancestors AS (
    SELECT
        id AS item_id,
        name,
        dt AS item_dt,
        parent_id,
        0 AS level
    FROM item
    WHERE name LIKE '%' || ? || '%'

    UNION ALL

    SELECT
        a.item_id,
        i.name,
        a.item_dt,
        i.parent_id,
        a.level + 1
    FROM ancestors a
    JOIN item i ON i.id = a.parent_id
)
SELECT
    item_id || ' | ' ||
    (
        SELECT group_concat(name, ' > ')
        FROM (
            SELECT name
            FROM ancestors a2
            WHERE a2.item_id = a.item_id
            ORDER BY level DESC
        )
    )
    ||
    CASE
        WHEN item_dt IS NOT NULL
        THEN ' > ' || item_dt
        ELSE ''
    END AS path
FROM ancestors a
WHERE level = 0
ORDER BY item_dt DESC;
