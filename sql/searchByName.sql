-- Find all items matching the name (case-insensitive/partial), recursively include
-- each match's descendants, and build the full path from root → item. Append the
-- item's description and date when present, and sort each subtree by date newest
-- → oldest (NULL dates last), with ID descending as a tie-breaker.
WITH RECURSIVE

matches AS (
    SELECT id
    FROM item
    WHERE name LIKE '%' || ? || '%'
),

subtree AS (
    SELECT
        i.id,
        i.parent_id,
        CASE
            WHEN i.dt IS NULL THEN '1'
            ELSE '0' || printf(
                '%010d',
                9999999 - CAST(julianday(i.dt) AS INTEGER)
            )
        END
        || '.' ||
        printf('%010d', 9999999999 - i.id) AS sort_path
    FROM item i
    JOIN matches m ON m.id = i.id

    UNION ALL

    SELECT
        i.id,
        i.parent_id,
        s.sort_path || '.' ||
        CASE
            WHEN i.dt IS NULL THEN '1'
            ELSE '0' || printf(
                '%010d',
                9999999 - CAST(julianday(i.dt) AS INTEGER)
            )
        END
        || '.' ||
        printf('%010d', 9999999999 - i.id)
    FROM item i
    JOIN subtree s ON i.parent_id = s.id
),

ancestors AS (
    SELECT
        i.id AS item_id,
        i.name,
        i.parent_id,
        0 AS level
    FROM item i
    JOIN subtree s ON s.id = i.id

    UNION ALL

    SELECT
        a.item_id,
        i.name,
        i.parent_id,
        a.level + 1
    FROM ancestors a
    JOIN item i ON i.id = a.parent_id
)

SELECT
    --printf('%1d', a.item_id) ||
    --' | ' ||
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
        WHEN leaf.description IS NOT NULL
        THEN ' - ' || leaf.description
        ELSE ''
    END
    ||
    CASE
        WHEN leaf.dt IS NOT NULL
        THEN ' (' || leaf.dt || ')'
        ELSE ''
    END
    ||
    ' [' || a.item_id || ']'
    AS path
FROM ancestors a
JOIN item leaf ON leaf.id = a.item_id
JOIN subtree s ON s.id = a.item_id
WHERE a.level = 0
ORDER BY s.sort_path;
