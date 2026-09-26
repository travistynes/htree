WITH RECURSIVE subtree AS (
    SELECT
        id,
        name,
        description,
        dt,
        parent_id,
        0 AS level,
        printf('%010d', 9999999999 - id) AS sort_path
    FROM item
    WHERE id = ?

    UNION ALL

    SELECT
        i.id,
        i.name,
        i.description,
        i.dt,
        i.parent_id,
        s.level + 1,
        s.sort_path || '.' || printf('%010d', 9999999999 - i.id)
    FROM item i
    JOIN subtree s ON i.parent_id = s.id
)
SELECT
    --id,
    CASE
        WHEN level = 0 THEN ''
        ELSE printf('%.*c', level, ' ')
    END ||
    name ||
    CASE
        WHEN description IS NOT NULL THEN ' > ' || description
        ELSE ''
    END ||
    CASE
        WHEN dt IS NOT NULL THEN ' > ' || dt
        ELSE ''
    END AS display
FROM subtree
ORDER BY sort_path;
