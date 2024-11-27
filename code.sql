-- TASK 3
-- ===========================================================================================
-- Author: Euan Jennings
-- Description: 
-- This view aggregates detailed performance data for each artist, including 
-- the number of concerts, songs performed, ticket sales metrics, and the last fan interaction.
-- The data is filtered to include artists with at least one concert and an average ticket 
-- price greater than 20.
-- ===========================================================================================

CREATE VIEW artist_concert_performance_details AS
SELECT 
    a.artist_id,
    a.artist_name,
    COUNT(DISTINCT ca.concert_id) AS num_concerts,     -- Number of concerts
    COUNT(DISTINCT cs.song_id) AS num_songs_performed, -- Number of songs performed
    AVG(t.ticket_price) AS avg_ticket_price,     -- Average ticket price
    SUM(t.ticket_price) AS total_ticket_sales,   -- Total ticket revenue
    COALESCE(MAX(c.date_of_concert), '1970-01-01') AS last_performance_date,  -- Last concert date
    COALESCE(MAX(f.fan_name), 'No Fans') AS last_fan_interaction  -- Last fan interaction
FROM 
    artists a
INNER JOIN 
    concert_artists ca ON a.artist_id = ca.artist_id     -- Join artists with the concerts they participated in
LEFT JOIN 
    concerts c ON ca.concert_id = c.concert_id           -- Join concerts data
RIGHT JOIN 
    ticket_concert tc ON c.concert_id = tc.concert_id    -- Join ticket-concert association
LEFT JOIN 
    tickets t ON tc.ticket_id = t.ticket_id              -- Join ticket data for pricing information
LEFT JOIN 
    concert_songs cs ON c.concert_id = cs.concert_id     -- Join songs performed at the concert
LEFT JOIN 
    ticket_fan tf ON t.ticket_id = tf.ticket_id          -- Join ticket-fan association for fan interactions
LEFT JOIN 
    fans f ON tf.fan_id = f.fan_id                       -- Join fans data for fan details
GROUP BY 
    a.artist_id, a.artist_name
HAVING 
    COUNT(DISTINCT ca.concert_id) >= 1   -- Ensure the artist has performed in at least one concert
    AND AVG(t.ticket_price) > 20;        -- Filter for artists with an average ticket price greater than 20


 --Task 6
-- ================================================================================
-- Author: Sean Conneally
-- Description:
-- # Checks if song_id(SON_001) is already associated with album_id(ALB_001),
--   if not it inserts the association into the album_songs table.
-- # Gets song release date and album release date,if song release date
--   is later then the album release date it updates song release date to match.
-- # Presumes both song_id_input and album_id_input exist in their respective tables.
-- ================================================================================

DELIMITER $$

CREATE PROCEDURE check_and_associate_song(
    IN song_id_input VARCHAR(16),
    IN album_id_input VARCHAR(16)
)
BEGIN
    DECLARE song_release_date DATE;
    DECLARE album_release_date DATE;

    SELECT release_date INTO song_release_date
    FROM songs
    WHERE song_id = song_id_input;

    SELECT release_date INTO album_release_date
    FROM albums
    WHERE album_id = album_id_input;

    IF NOT EXISTS (
        SELECT 1
        FROM album_songs
        WHERE song_id = song_id_input AND album_id = album_id_input
    ) THEN
        INSERT INTO album_songs (album_id, song_id)
        VALUES (album_id_input, song_id_input);
    END IF;

    IF song_release_date > album_release_date THEN
        UPDATE songs
        SET release_date = album_release_date
        WHERE song_id = song_id_input;
    END IF;
END$$

DELIMITER ;


