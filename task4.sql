-- =============================================================
-- Author: Tommy Quinn
-- Description: 
--Prevents duplicate artist names from being inserted into the 
--        'artists' table.
-- =============================================================

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
