--Task 5
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
