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
