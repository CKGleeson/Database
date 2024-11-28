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
