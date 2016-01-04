#ufnGetProductType('CarTypeName')
DROP FUNCTION IF EXISTS ufnGetProductType;
DELIMITER $$
CREATE FUNCTION ufnGetProductType (
    MyCarTypeName VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE MyProductTypeName VARCHAR(255);
    
    SET MyProductTypeName = (SELECT o1.*
        FROM (SELECT ProductTypeName
            FROM IndustryProducts
            WHERE ProductTypeName IN (SELECT ProductTypeName
                FROM ProductTypes
                WHERE CarTypeName = MyCarTypeName)
            AND isProducer = TRUE) o1
        JOIN (SELECT ProductTypeName
            FROM IndustryProducts
            WHERE ProductTypeName IN (SELECT ProductTypeName
                FROM ProductTypes
                WHERE CarTypeName = MyCarTypeName)
            AND isProducer = FALSE) o2
        WHERE o1.ProductTypeName = o2.ProductTypeName
        GROUP BY o1.ProductTypeName
        ORDER BY RAND() LIMIT 0, 1);
        
    RETURN MyProductTypeName;
END$$
DELIMITER ;

#ufnGetProducingIndustry(CarLength, 'ProductTypeName')
DROP FUNCTION IF EXISTS ufnGetProducingIndustry;
DELIMITER $$
CREATE FUNCTION ufnGetProducingIndustry (
    MyCarLength INT,
    MyProductTypeName VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE MyIndustryName VARCHAR(255);
    
    DROP TEMPORARY TABLE IF EXISTS P_IndustriesFilter;
    CREATE TEMPORARY TABLE P_IndustriesFilter (
        IndustryName VARCHAR(255) NOT NULL PRIMARY KEY
    );
    
    INSERT INTO P_IndustriesFilter (IndustryName)
        SELECT s.IndustryName
            FROM IndustrySidings s
            JOIN IndustryProducts p ON s.IndustryName = p.IndustryName
            WHERE s.AvailableLength >= MyCarLength
            AND s.IndustryName IN (SELECT IndustryName
                FROM IndustriesAvailable
                WHERE IsAvailable = TRUE)
            AND s.SidingNumber IN (SELECT SidingNumber
                FROM SidingAssignments
                WHERE ProductTypeName = MyProductTypeName)
            AND p.ProductTypeName = MyProductTypeName
            AND p.IsProducer = TRUE
            GROUP BY s.IndustryName
            UNION SELECT s.IndustryName
            FROM IndustrySidings s
            JOIN IndustryProducts p ON s.IndustryName = p.IndustryName
            WHERE s.AvailableLength >= MyCarLength
            AND s.IndustryName IN (SELECT IndustryName
                FROM IndustriesAvailable
                WHERE IsAvailable = TRUE)
            AND s.IndustryName NOT IN (SELECT IndustryName
                FROM SidingAssignments
                WHERE ProductTypeName = MyProductTypeName)
            AND p.ProductTypeName = MyProductTypeName
            AND p.IsProducer = TRUE
            GROUP BY s.IndustryName;
    
    DROP TEMPORARY TABLE IF EXISTS P_IndustriesList;
    CREATE TEMPORARY TABLE P_IndustriesList (
        IndustryID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        IndustryName VARCHAR(255) NOT NULL
    );
    
    SET @minimumActivity = (SELECT MIN(ActivityLevel)
        FROM IndustryProducts p
        JOIN IndustryActivities a ON p.IndustryName = a.IndustryName
        WHERE p.ProductTypeName = MyProductTypeName
        AND p.IndustryName IN (
            SELECT IndustryName
            FROM P_IndustriesFilter));
    SET @maximumActivity = (SELECT MAX(ActivityLevel)
        FROM IndustryProducts p
        JOIN IndustryActivities a ON p.IndustryName = a.IndustryName
        WHERE p.ProductTypeName = MyProductTypeName
        AND p.IndustryName IN (
            SELECT IndustryName
            FROM P_IndustriesFilter));
    SET @activityLevel = @maximumActivity;
    
    WHILE (@activityLevel >= @minimumActivity) DO
        SET @counter = @minimumActivity;
        
        WHILE (@counter <= @activityLevel) DO
            INSERT INTO P_IndustriesList (IndustryID, IndustryName)
                SELECT NULL, p.IndustryName
                    FROM IndustryProducts p
                    JOIN IndustryActivities a ON p.IndustryName = a.IndustryName
                    WHERE p.IndustryName IN (
                        SELECT IndustryName
                        FROM P_IndustriesFilter)
                    AND p.ProductTypeName = MyProductTypeName
                    AND p.IsProducer = TRUE
                    AND a.ActivityLevel = @activityLevel;
            SET @counter = @counter + 1;
        END WHILE;
        
        SET @activityLevel = @activityLevel - 1;
    END WHILE;

    SET MyIndustryName = (SELECT IndustryName
        FROM P_IndustriesList
        ORDER BY RAND() LIMIT 0, 1);
        
    RETURN MyIndustryName;
    
    DROP TEMPORARY TABLE IF EXISTS P_IndustriesFilter;
    DROP TEMPORARY TABLE IF EXISTS P_IndustriesList;
END$$
DELIMITER ;

#ufnGetConsumingIndustry(CarLength, 'ProductTypeName')
DROP FUNCTION IF EXISTS ufnGetConsumingIndustry;
DELIMITER $$
CREATE FUNCTION ufnGetConsumingIndustry (
    MyCarLength INT,
    MyProductTypeName VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE MyIndustryName VARCHAR(255);
    
    DROP TEMPORARY TABLE IF EXISTS C_IndustriesFilter;
    CREATE TEMPORARY TABLE C_IndustriesFilter (
        IndustryName VARCHAR(255) NOT NULL PRIMARY KEY
    );
    
    INSERT INTO C_IndustriesFilter (IndustryName)
        SELECT s.IndustryName
            FROM IndustrySidings s
            JOIN IndustryProducts p ON s.IndustryName = p.IndustryName
            WHERE s.AvailableLength >= MyCarLength
            AND s.IndustryName IN (SELECT IndustryName
                FROM IndustriesAvailable
                WHERE IsAvailable = TRUE)
            AND s.SidingNumber IN (SELECT SidingNumber
                FROM SidingAssignments
                WHERE ProductTypeName = MyProductTypeName)
            AND p.ProductTypeName = MyProductTypeName
            AND p.IsProducer = FALSE
            GROUP BY s.IndustryName
        UNION SELECT s.IndustryName
            FROM IndustrySidings s
            JOIN IndustryProducts p ON s.IndustryName = p.IndustryName
            WHERE s.AvailableLength >= MyCarLength
            AND s.IndustryName IN (SELECT IndustryName
                FROM IndustriesAvailable
                WHERE IsAvailable = TRUE)
            AND s.IndustryName NOT IN (SELECT IndustryName
                FROM SidingAssignments
                WHERE ProductTypeName = MyProductTypeName)
            AND p.ProductTypeName = MyProductTypeName
            AND p.IsProducer = FALSE
            GROUP BY s.IndustryName;
    
    DROP TEMPORARY TABLE IF EXISTS C_IndustriesList;
    CREATE TEMPORARY TABLE C_IndustriesList (
        IndustryID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        IndustryName VARCHAR(255) NOT NULL
    );
    
    SET @minimumActivity = (SELECT MIN(ActivityLevel)
        FROM IndustryProducts p
        JOIN IndustryActivities a ON p.IndustryName = a.IndustryName
        WHERE p.ProductTypeName = MyProductTypeName
        AND p.IndustryName IN (
            SELECT IndustryName
            FROM C_IndustriesFilter));
    SET @maximumActivity = (SELECT MAX(ActivityLevel)
        FROM IndustryProducts p
        JOIN IndustryActivities a ON p.IndustryName = a.IndustryName
        WHERE p.ProductTypeName = MyProductTypeName
        AND p.IndustryName IN (
            SELECT IndustryName
            FROM C_IndustriesFilter));
    SET @activityLevel = @maximumActivity;
    
    WHILE (@activityLevel >= @minimumActivity) DO
        SET @counter = @minimumActivity;

        WHILE (@counter <= @activityLevel) DO
            INSERT INTO C_IndustriesList (IndustryID, IndustryName)
                SELECT NULL, p.IndustryName
                    FROM IndustryProducts p
                    JOIN IndustryActivities a ON p.IndustryName = a.IndustryName
                    WHERE p.IndustryName IN (
                        SELECT IndustryName
                        FROM C_IndustriesFilter)
                    AND p.ProductTypeName = MyProductTypeName
                    AND p.IsProducer = FALSE
                    AND a.ActivityLevel = @activityLevel;
            SET @counter = @counter + 1;
        END WHILE;
        
        SET @activityLevel = @activityLevel - 1;
    END WHILE;  
    
    SET MyIndustryName = (SELECT IndustryName
        FROM C_IndustriesList
        ORDER BY RAND() LIMIT 0, 1);
        
    RETURN MyIndustryName;
    
    DROP TEMPORARY TABLE IF EXISTS C_IndustriesFilter;
    DROP TEMPORARY TABLE IF EXISTS C_IndustriesList;
END$$
DELIMITER ;

#ufnGetIndustrySiding('IndustryName', 'ProductTypeName')
DROP FUNCTION IF EXISTS ufnGetIndustrySiding;
DELIMITER $$
CREATE FUNCTION ufnGetIndustrySiding (
    MyIndustryName VARCHAR(255),
    MyProductTypeName VARCHAR(255))
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE MySidingNumber INT;
    
    DROP TEMPORARY TABLE IF EXISTS SidingsList;
    CREATE TEMPORARY TABLE SidingsList (
        SidingNumber INT NOT NULL PRIMARY KEY,
        AvailableLength INT NOT NULL
    );
    
    INSERT INTO SidingsList (SidingNumber, AvailableLength)
        SELECT s.SidingNumber, s.AvailableLength
            FROM IndustrySidings s
            JOIN IndustryProducts p ON s.IndustryName = p.IndustryName
            WHERE p.ProductTypeName NOT IN (SELECT ProductTypeName
                FROM SidingAssignments
                WHERE IndustryName = MyIndustryName)
                AND s.SidingNumber NOT IN (SELECT SidingNumber
                    FROM SidingAssignments
                    WHERE IndustryName = MyIndustryName)
                AND s.IndustryName = MyIndustryName
                AND p.ProductTypeName = MyProductTypeName
            UNION SELECT s.SidingNumber, s.AvailableLength
            FROM IndustrySidings s
            JOIN IndustryProducts p ON s.IndustryName = p.IndustryName
            WHERE p.ProductTypeName IN (SELECT ProductTypeName
                FROM SidingAssignments
                WHERE IndustryName = MyIndustryName)
                AND s.SidingNumber IN (SELECT SidingNumber
                    FROM SidingAssignments
                    WHERE IndustryName = MyIndustryName)
                AND s.IndustryName = MyIndustryName
                AND p.ProductTypeName = MyProductTypeName;
    
    SET MySidingNumber = (SELECT SidingNumber
        FROM SidingsList
        ORDER BY AvailableLength DESC LIMIT 1);
        
    RETURN MySidingNumber;
    
    DROP TEMPORARY TABLE IF EXISTS SidingsList;
END$$
DELIMITER ;

#ufnGetCarModuleName('CarID')
DROP FUNCTION IF EXISTS ufnGetCarModuleName;
DELIMITER $$
CREATE FUNCTION ufnGetCarModuleName (
    MyCarID VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE MyModuleName VARCHAR(255);
    
    IF (MyCarID IN (SELECT CarID FROM ConsistedCars WHERE CarID = MyCarID)) THEN
        SET MyModuleName = (SELECT ModuleName
            FROM TrainLocations
            WHERE TrainNumber = (SELECT TrainNumber
                FROM ConsistedCars
                WHERE CarID = MyCarID));
    ELSEIF (MyCarID IN (SELECT CarID FROM RollingStockAtYards WHERE CarID = MyCarID)) THEN
        SET MyModuleName = (SELECT ModuleName
            FROM Yards
            WHERE YardName = (SELECT YardName
                FROM RollingStockAtYards
                WHERE CarID = MyCarID));
    ELSE
        SET MyModuleName = (SELECT ModuleName
            FROM Industries
            WHERE IndustryName = (SELECT IndustryName
                FROM RollingStockAtIndustries
                WHERE CarID = MyCarID));
    END IF;

    RETURN MyModuleName;
END$$
DELIMITER ;

#ufnCheckServiceableCarSiding('ProductTypeName', 'IndustryName', SidingNumber)
DROP FUNCTION IF EXISTS ufnCheckServiceableCarSiding;
DELIMITER $$
CREATE FUNCTION ufnCheckServiceableCarSiding (
    MyProductTypeName VARCHAR(255),
    MyIndustryName VARCHAR(255),
    MySidingNumber INT)
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE ServiceableCarSiding BOOL;

    DROP TEMPORARY TABLE IF EXISTS SidingsFilter;
    CREATE TEMPORARY TABLE SidingsFilter (
        SidingNumber INT NOT NULL PRIMARY KEY
    );
    
    INSERT INTO SidingsFilter (SidingNumber)
        SELECT s.SidingNumber
            FROM IndustrySidings s
            JOIN IndustryProducts p ON s.IndustryName = p.IndustryName
            WHERE p.ProductTypeName NOT IN (SELECT ProductTypeName
                FROM SidingAssignments
                WHERE IndustryName = MyIndustryName)
                AND s.SidingNumber NOT IN (SELECT SidingNumber
                    FROM SidingAssignments
                    WHERE IndustryName = MyIndustryName)
                AND s.IndustryName = MyIndustryName
                AND p.ProductTypeName = MyProductTypeName
            UNION SELECT s.SidingNumber
            FROM IndustrySidings s
            JOIN IndustryProducts p ON s.IndustryName = p.IndustryName
            WHERE p.ProductTypeName IN (SELECT ProductTypeName
                FROM SidingAssignments
                WHERE IndustryName = MyIndustryName)
                AND s.SidingNumber IN (SELECT SidingNumber
                    FROM SidingAssignments
                    WHERE IndustryName = MyIndustryName)
                AND s.IndustryName = MyIndustryName
                AND p.ProductTypeName = MyProductTypeName;
    
    SET ServiceableCarSiding = (SELECT MySidingNumber IN (SELECT SidingNumber
            FROM SidingsFilter
            WHERE SidingNumber = MySidingNumber));
    
    RETURN ServiceableCarSiding;
    
    DROP TEMPORARY TABLE IF EXISTS SidingsFilter;
END$$
DELIMITER ;

#ufnGetNextDestination('CarID')

#ufnGetNextSiding('CarID)

#ufnGetNextLocation('CarID')

#ufnGetCarLoadStatus('CarID')