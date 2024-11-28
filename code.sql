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


-- TASK 4
-- =============================================================
-- Author: Tommy Quinn
-- Description: 
-- # Prevents duplicate artist names from being inserted into the 
--   'artists' table (Before Trigger).
-- # Automatically increases ticket prices by 10% for tickets associated 
--   with a concert if the concert's location is updated (After Trigger).
-- =============================================================

-- Before Trigger: Prevents duplicate artist names

DELIMITER $$
CREATE TRIGGER before_insert_artist
BEFORE INSERT ON artists
FOR EACH ROW
BEGIN
    -- Declare a variable to store the count of duplicate artist names
    DECLARE duplicate_count INT;

    -- Count the number of existing records with the same artist name as the new record
    SELECT COUNT(*) INTO duplicate_count 
    FROM artists 
    WHERE artist_name = NEW.artist_name;

    -- If a duplicate is found, raise an error and prevent the insert operation
    IF duplicate_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Artist name already exists!';
    END IF;
END$$
DELIMITER ;


-- After Trigger: Updates ticket prices when a concert location changes

DELIMITER $$
CREATE TRIGGER after_update_concert
AFTER UPDATE ON concerts
FOR EACH ROW
BEGIN
    -- Check if the concert location has changed
    IF OLD.location <> NEW.location THEN
        -- Update ticket prices by increasing them by 10% for tickets linked to the concert
        UPDATE tickets
        SET ticket_price = ticket_price * 1.10
        WHERE ticket_id IN (
            -- Select ticket IDs associated with the updated concert
            SELECT ticket_id 
            FROM ticket_concert 
            WHERE concert_id = NEW.concert_id
        );
    END IF;
END$$
DELIMITER ;


--TASK 5
-- ================================================================================
-- Author: Sean Coughlan
-- Description: 
-- # My function, TotalOccupiedSeats, takes a concert_id as input and returns the 
--   total number of unique seats that are occupied for that specific concert.
--================================================================================


CREATE FUNCTION TotalOccupiedSeats(concert_id VARCHAR(16)) 
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total_seats INT;

    -- Count the total number of unique seat numbers occupied for the given concert
    SELECT COUNT(DISTINCT tf.seat_number)
    INTO total_seats
    FROM ticket_fan tf
    INNER JOIN ticket_concert tc ON tf.ticket_id = tc.ticket_id
    WHERE tc.concert_id = concert_id;

    -- Return the result
    RETURN COALESCE(total_seats, 0);
END;


-- TASK 6
-- ================================================================================
-- Author: Sean Conneally
-- Description:
-- # Checks if song_id(SON_001) is already associated with album_id(ALB_001),
--   if not it inserts the association into the album_songs table.
-- # Gets song release date and album release date. If the song release date
--   is later than the album release date, it updates the song release date 
--   to match the album release date.
-- # Presumes both song_id_input and album_id_input exist in their respective tables.
-- ================================================================================

DELIMITER $$
CREATE PROCEDURE check_and_associate_song(
    IN song_id_input VARCHAR(16), -- Input parameter for the song ID
    IN album_id_input VARCHAR(16) -- Input parameter for the album ID
)
BEGIN
    -- Declare variables to store the release dates of the song and album
    DECLARE song_release_date DATE;
    DECLARE album_release_date DATE;

    -- Fetch the release date of the song using the provided song_id_input
    SELECT release_date INTO song_release_date
    FROM songs
    WHERE song_id = song_id_input;

    -- Fetch the release date of the album using the provided album_id_input
    SELECT release_date INTO album_release_date
    FROM albums
    WHERE album_id = album_id_input;

    -- Check if the song is already associated with the album
    IF NOT EXISTS (
        SELECT 1
        FROM album_songs
        WHERE song_id = song_id_input AND album_id = album_id_input
    ) THEN
        -- If the association does not exist, insert it into the album_songs table
        INSERT INTO album_songs (album_id, song_id)
        VALUES (album_id_input, song_id_input);
    END IF;

    -- Check if the song's release date is later than the album's release date
    IF song_release_date > album_release_date THEN
        -- Update the song's release date to match the album's release date
        UPDATE songs
        SET release_date = album_release_date
        WHERE song_id = song_id_input;
    END IF;
END$$
DELIMITER ;
