#uspAddTrain(TrainNumber, LeadPower, DCCAddress, 'ModuleName')
#Add a player train to a game session.  The train must originate on a module
#   that has been declared available.
#Pre-conditions:
#-- The given TrainNumber must be unique.
#-- Valid Modules and ModulesAvailable entities must exist and match the given
#   ModuleName input.
#Post-conditions:  A Trains entity and TrainLocations entity is created.
DROP PROCEDURE IF EXISTS uspAddTrain;
DELIMITER $$
CREATE PROCEDURE uspAddTrain (
    IN MyTrainNumber INT,
    IN MyLeadPower VARCHAR(255),
    IN MyDCCAddress CHAR(4),
    IN MyModuleName VARCHAR(255))
BEGIN
    IF (MyTrainNumber IN (SELECT TrainNumber FROM Trains WHERE TrainNumber = MyTrainNumber)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Train already exists.';
    ELSEIF (MyModuleName NOT IN (SELECT ModuleName FROM ModulesAvailable WHERE ModuleName = MyModuleName)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Location does not exist or is not active.';
    ELSE
        INSERT INTO Trains VALUES (MyTrainNumber, MyLeadPower, MyDCCAddress, DEFAULT);
        INSERT INTO TrainLocations VALUES (MyTrainNumber, MyModuleName, DEFAULT);
    END IF;
END$$
DELIMITER ;

#uspRemoveTrain(TrainNumber)
#Remove a player train from a game session.  A player train cannot be removed
#   if it has consisted cars.
#Pre-conditions:
#-- A valid Trains entity must exist and match the given TrainNumber input.
#-- The given TrainNumber attribute must not exist in any ConsistedCars
#   entities.
#Post-conditions:  The supplied Trains and TrainLocations entities are deleted.
DROP PROCEDURE IF EXISTS uspRemoveTrain;
DELIMITER $$
CREATE PROCEDURE uspRemoveTrain (
    IN MyTrainNumber INT)
BEGIN
    IF (MyTrainNumber NOT IN (SELECT TrainNumber FROM Trains WHERE TrainNumber = MyTrainNumber)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Train not found.';
    ELSEIF (MyTrainNumber IN (SELECT TrainNumber FROM ConsistedCars WHERE TrainNumber = MyTrainNumber)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Train has remaining consisted cars.';
    ELSE
        DELETE FROM Trains WHERE TrainNumber = MyTrainNumber;
    END IF;
END$$
DELIMITER ;

#uspModifyTrain(TrainNumber, LeadPower, DCCAddress)
#Update the LeadPower (locomotive number) and DCCAddress descriptions for a
#   player train.
#Pre-conditions:  A valid Trains entity must exist.
#Post-conditions:  The LeadPower and DCCAddress attributes are modified on the
#   Trains entity.
DROP PROCEDURE IF EXISTS uspModifyTrain;
DELIMITER $$
CREATE PROCEDURE uspModifyTrain (
    IN MyTrainNumber INT,
    IN NewLeadPower VARCHAR(255),
    IN NewDCCAddress CHAR(4))
BEGIN
    IF (MyTrainNumber NOT IN (SELECT TrainNumber FROM Trains WHERE TrainNumber = MyTrainNumber)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Train not found.';
    ELSE
        UPDATE Trains SET LeadPower = NewLeadPower, DCCAddress = NewDCCAddress WHERE TrainNumber = MyTrainNumber;
    END IF;
END$$
DELIMITER ;

#uspAddCarToGame('CarID', 'CarTypeName', 'YardName')
#Add a rolling stock car to a game session for player use.  Declare an
#   identifying name and valid car type for each rolling stock car.  Cars are
#   to be added to yards for initial classification.
#Pre-conditions:
#-- The given CarID must be unique.
#-- A valid RollingStockTypes entity must exist for the given CarTypeName.
#-- A valid Yards entity must exist for the given YardName.
#Post-conditions:  A RollingStockCars and RollingStockAtYards entity is
#   created.
DROP PROCEDURE IF EXISTS uspAddCarToGame;
DELIMITER $$
CREATE PROCEDURE uspAddCarToGame (
    IN MyCarID VARCHAR(255),
    IN MyCarTypeName VARCHAR(255),
    IN MyYardName VARCHAR(255))
BEGIN
    CASE
        WHEN (MyCarID IN (SELECT CarID FROM RollingStockCars WHERE CarID = MyCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car already exists.';
        WHEN (MyCarTypeName NOT IN (SELECT CarTypeName FROM RollingStockTypes WHERE CarTypeName = MyCarTypeName)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car type does not exist.';
        WHEN (MyYardName NOT IN (SELECT YardName FROM Yards WHERE YardName = MyYardName)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Yard does not exist.';
        ELSE
            INSERT INTO RollingStockCars VALUES (MyCarID, MyCarTypeName);
            INSERT INTO RollingStockAtYards VALUES (MyCarID, MyYardName, DEFAULT);
    END CASE;
END$$
DELIMITER ;

#uspRemoveCarFromGame('CarID')
#Remove a rolling stock car from a game session.  Cars cannot be removed if
#   they are consisted to a train or have a waybill and are in service.
#Pre-conditions:
#-- A valid RollingStockCars entity must exist.
#-- Associated ConsistedCars and Waybills entities must not exist.
#Post-conditions:  The supplied RollingStockCars, RollingStockAtIndustries, and
#   RollingStockAtYards entites are deleted. 
DROP PROCEDURE IF EXISTS uspRemoveCarFromGame;
DELIMITER $$
CREATE PROCEDURE uspRemoveCarFromGame (
    IN MyCarID VARCHAR(255))
BEGIN
    CASE
        WHEN (MyCarID NOT IN (SELECT CarID FROM RollingStockCars WHERE CarID = MyCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car not found.';
        WHEN (MyCarID IN (SELECT CarID FROM ConsistedCars WHERE CarID = MyCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car is consisted to a train and cannot be removed.';
        WHEN (MyCarID IN (SELECT CarID FROM Waybills WHERE CarID = MyCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car has existing waybill and cannot be removed.';
        ELSE
            DELETE FROM RollingStockCars WHERE CarID = MyCarID;
    END CASE;
END$$
DELIMITER ;

#uspAddCarToService('CarID')
#Generate a shipping order and associate a waybill to a rolling stock car that
#   is active (added) in a game session.  To be added to service, the rolling
#   stock car must not currently be in service.  A car will not be able to be
#   added to service if its associated product type does not have a producer
#   and consumer industry on the current layout, or if industries report that
#   they are at production capacity and no goods are available to ship.  An
#   industry will become available again after it is serviced by players.
#Pre-conditions:
#-- A valid RollingStockTypes entity must exist.
#-- An associated Waybills entity must not exist.
#-- For a given car type, the product type must be allowable on the current
#   layout.
#-- For a given product type, an associated producing industry must have
#   available length greater than the given rolling stock car's length on an
#   industry siding.
#-- For a given product type, an associated consuming industry must have
#   available length greater than the given rolling stock car's length on an
#   industry siding.
#Post-conditions:
#-- A Shipments entity is created.
#-- A Waybills entity is created and associated with the given RollingStockCars
#   entity.
#-- AvailableLength is reduced by the rolling stock car's length on an assigned
#   producing industry siding.
DROP PROCEDURE IF EXISTS uspAddCarToService;
DELIMITER $$
CREATE PROCEDURE uspAddCarToService (
    IN MyCarID VARCHAR(255))
BEGIN
    DECLARE MyCarTypeName VARCHAR(255);
    DECLARE MyProductTypeName VARCHAR(255);
    DECLARE MyCarLength INT;
    DECLARE MyFromIndustry VARCHAR(255);
    DECLARE MyToIndustry VARCHAR(255);
    DECLARE MyFromSiding INT;
    DECLARE MyToSiding INT;
    DECLARE MyYardName VARCHAR(255);
    
    #Do basic qualifications for this car to see if it is eligible for service.
    IF (MyCarID NOT IN (SELECT CarID FROM RollingStockCars WHERE CarID = MyCarID)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Car not found.';
    ELSEIF (MyCarID IN (SELECT CarID FROM Waybills WHERE CarID = MyCarID)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Car already in service.';
    ELSE
        #The car is qualified to be assigned to a shipping order.  Check if the
        #layout is capable of producing and consuming a product type this car
        #can carry.  If so, assign one.
        SET MyCarTypeName = (SELECT CarTypeName
            FROM RollingStockCars
            WHERE CarID = MyCarID);
        SET MyProductTypeName = ufnGetProductType(MyCarTypeName);
        
        IF (MyProductTypeName IS NULL) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No industry orders for this car type on this layout.';
        ELSE
            #A pair of producing and consuming industries servicing the
            #assigned product type are guaranteed to exist.  Check if there is
            #a producing industry of this product type that has room for this
            #rolling stock car's length.  If so, assign it as a load point.
            #Check if there is a consuming industry of this product type that
            #has room for this rolling stock car's length.  If so, assign it as
            #an unload point.
            SET MyCarLength = (SELECT CarLength
                FROM RollingStockTypes
                WHERE CarTypeName = MyCarTypeName);
            SET MyFromIndustry = ufnGetProducingIndustry(MyCarLength, MyProductTypeName);
            SET MyToIndustry = ufnGetConsumingIndustry(MyCarLength, MyProductTypeName);
            
            IF (MyFromIndustry IS NULL OR MyToIndustry IS NULL) THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'No industry orders at this time.';
            ELSE
                #Both a producing industry and consuming industry are
                #guaranteed to accept delivery.  Assign the industry sidings
                #with the most free space for loading and unloading.  If siding
                #assignments exist for the chosen product type, use them.
                SET MyFromSiding = ufnGetIndustrySiding(MyFromIndustry, MyProductTypeName);
                SET MyToSiding = ufnGetIndustrySiding(MyToIndustry, MyProductTypeName);
                
                #Create the shipping order.  Reduce the reported available
                #length at the producing industry's siding by the incoming
                #car's length.
                INSERT INTO Shipments VALUES (DEFAULT, MyProductTypeName, MyFromIndustry, MyFromSiding, MyToIndustry, MyToSiding, DEFAULT);
                UPDATE IndustrySidings SET AvailableLength = AvailableLength - MyCarLength WHERE IndustryName = MyFromIndustry AND SidingNumber = MyFromSiding;
                
                #Create the waybill.  Randomly assign a return yard for the car
                #to use after the shipping order is completed.
                SET MyYardName = (SELECT YardName
                    FROM Yards
                    ORDER BY RAND() LIMIT 0, 1);   
                INSERT INTO Waybills VALUES (MyCarID, LAST_INSERT_ID(), MyYardName);
            END IF;
        END IF;
    END IF;
END$$
DELIMITER ;

#uspRemoveCarFromService('CarID')
DROP PROCEDURE IF EXISTS uspRemoveCarFromService;
DELIMITER $$
CREATE PROCEDURE uspRemoveCarFromService (
    IN MyCarID VARCHAR(255))
BEGIN
    DECLARE MyShipmentID INT;
    DECLARE ShipmentCompleted BOOL;
    DECLARE ShipmentCanceled BOOL;
    DECLARE MyCarLength INT;
    DECLARE MyFromIndustry VARCHAR(255);
    DECLARE MyFromSiding INT;
    
    IF (MyCarID NOT IN (SELECT CarID FROM RollingStockCars WHERE CarID = MyCarID)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Car not found.';
    ELSEIF (MyCarID NOT IN (SELECT CarID FROM Waybills WHERE CarID = MyCarID)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Car not in service.';
    ELSE
        SET MyShipmentID = (SELECT ShipmentID
            FROM Waybills
            WHERE CarID = MyCarID);
        SET ShipmentCompleted = MyShipmentID IN (SELECT ShipmentID
                FROM ShipmentsLoaded
                WHERE ShipmentID = MyShipmentID)
            AND MyShipmentID IN (SELECT ShipmentID
                FROM ShipmentsUnloaded
                WHERE ShipmentID = MyShipmentID);
        SET ShipmentCanceled = MyShipmentID NOT IN (SELECT ShipmentID
                FROM ShipmentsLoaded
                WHERE ShipmentID = MyShipmentID)
            AND MyShipmentID NOT IN (SELECT ShipmentID
                FROM ShipmentsUnloaded
                WHERE ShipmentID = MyShipmentID);
                    
        IF (ShipmentCompleted) THEN
            DELETE FROM Waybills WHERE CarID = MyCarID; 
        ELSEIF (ShipmentCanceled) THEN
            DELETE FROM Waybills WHERE CarID = MyCarID;      

            SET MyCarLength = (SELECT CarLength
                FROM RollingStockTypes
                WHERE CarTypeName = (SELECT CarTypeName
                    FROM RollingStockCars
                    WHERE CarID = MyCarID));
            SET MyFromIndustry = (SELECT FromIndustry
                FROM Shipments
                WHERE ShipmentID = MyShipmentID);
            SET MyFromSiding = (SELECT FromSiding
                FROM Shipments
                WHERE ShipmentID = MyShipmentID);
                
            UPDATE IndustrySidings SET AvailableLength = AvailableLength + MyCarLength WHERE IndustryName = MyFromIndustry AND SidingNumber = MyFromSiding;
        ELSE
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car has open waybill and cannot be removed.';
        END IF;
    END IF;
END$$
DELIMITER ;

#uspModifyCarInService('OldCarID', 'NewCarID')
DROP PROCEDURE IF EXISTS uspModifyCarInService;
DELIMITER $$
CREATE PROCEDURE uspModifyCarInService (
    IN OldCarID VARCHAR(255),
    IN NewCarID VARCHAR(255))
BEGIN
    CASE
        WHEN (OldCarID NOT IN (SELECT CarID FROM RollingStockCars WHERE CarID = OldCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Originating car not found.';
        WHEN (NewCarID NOT IN (SELECT CarID FROM RollingStockCars WHERE CarID = NewCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Replacement car not found.';
        WHEN (NewCarID IN (SELECT CarID FROM Waybills WHERE CarID = NewCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Replacement car has existing waybill.';
        ELSE
            SET @oldCarType = (SELECT CarTypeName
                FROM RollingStockCars
                WHERE CarID = OldCarID);
            SET @newCarType = (SELECT CarTypeName
                FROM RollingStockCars
                WHERE CarID = NewCarID);
            IF (@oldCarType <> @newCarType) THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Replacement car type does not match original car type.';
            ELSE
                UPDATE Waybills SET CarID = NewCarID WHERE CarID = OldCarID;
            END IF;
    END CASE;
END$$
DELIMITER ;

#uspAddCrewToTrain(TrainNumber, 'CrewName')
DROP PROCEDURE IF EXISTS uspAddCrewToTrain;
DELIMITER $$
CREATE PROCEDURE uspAddCrewToTrain (
    IN MyTrainNumber INT,
    IN MyCrewName VARCHAR(255))
BEGIN
    IF (MyTrainNumber NOT IN (SELECT TrainNumber FROM Trains WHERE TrainNumber = MyTrainNumber)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Train not found.';
    ELSEIF (MyCrewName IN (SELECT CrewName from TrainCrews WHERE CrewName = MyCrewName)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Crew already assigned to another train.';
    ELSE
        INSERT INTO TrainCrews VALUES (MyTrainNumber, MyCrewName, DEFAULT);
    END IF;
END$$
DELIMITER ;

#uspRemoveCrewFromTrain(TrainNumber)
DROP PROCEDURE IF EXISTS uspRemoveCrewFromTrain;
DELIMITER $$
CREATE PROCEDURE uspRemoveCrewFromTrain (
    IN MyTrainNumber INT)
BEGIN
    IF (MyTrainNumber NOT IN (SELECT TrainNumber FROM Trains WHERE TrainNumber = MyTrainNumber)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Train not found.';
    ELSEIF (MyTrainNumber NOT IN (SELECT TrainNumber FROM TrainCrews WHERE TrainNumber = MyTrainNumber)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Train not assigned a crew.';
    ELSE
        DELETE FROM TrainCrews WHERE TrainNumber = MyTrainNumber;
    END IF;
END$$
DELIMITER ;

#uspMoveTrain(TrainNumber, 'ModuleName')
DROP PROCEDURE IF EXISTS uspMoveTrain;
DELIMITER $$
CREATE PROCEDURE uspMoveTrain (
    IN MyTrainNumber INT,
    IN MyModuleName VARCHAR(255))
BEGIN
    CASE
        WHEN (MyTrainNumber NOT IN (SELECT TrainNumber FROM Trains WHERE TrainNumber = MyTrainNumber)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Train not found.';
        WHEN (MyModuleName NOT IN (SELECT ModuleName FROM ModulesAvailable WHERE ModuleName = MyModuleName)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Location does not exist or is not active.';
        WHEN (MyTrainNumber NOT IN (SELECT TrainNumber FROM TrainCrews WHERE TrainNumber = MyTrainNumber)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Train is not crewed and cannot move.';
        WHEN (MyModuleName IN (SELECT ModuleName FROM TrainLocations WHERE TrainNumber = MyTrainNumber)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Train was already at that location.';
        ELSE
            UPDATE TrainLocations SET ModuleName = MyModuleName WHERE TrainNumber = MyTrainNumber;
    END CASE;
END$$
DELIMITER ;

#uspMoveCarToTrain(TrainNumber, 'CarID')
DROP PROCEDURE IF EXISTS uspMoveCarToTrain;
DELIMITER $$
CREATE PROCEDURE uspMoveCarToTrain (
    IN MyTrainNumber INT,
    IN MyCarID VARCHAR(255))
BEGIN
    CASE
        WHEN (MyTrainNumber NOT IN (SELECT TrainNumber FROM Trains WHERE TrainNumber = MyTrainNumber)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Train not found.';
        WHEN (MyCarID NOT IN (SELECT CarID FROM RollingStockCars WHERE CarID = MyCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car not found.';
        WHEN (MyCarID IN (SELECT CarID FROM ConsistedCars WHERE TrainNumber = MyTrainNumber AND CarID = MyCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car is already in your train.';
        WHEN (MyCarID IN (SELECT MyCarID FROM ConsistedCars WHERE CarID = MyCarID) AND MyTrainNumber <> (SELECT TrainNumber FROM ConsistedCars WHERE CarID = MyCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car is still consisted to another train.';
        WHEN ((SELECT ModuleName FROM TrainLocations WHERE TrainNumber = MyTrainNumber) <> ufnGetCarModuleName(MyCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car is not in the same location as the train.';
        WHEN (MyCarID IN (SELECT CarID FROM RollingStockAtYards WHERE CarID = MyCarID)) THEN
            INSERT INTO ConsistedCars VALUES (MyTrainNumber, MyCarID, DEFAULT);
            DELETE FROM RollingStockAtYards WHERE CarID = MyCarID;
        WHEN (MyCarID IN (SELECT CarID FROM RollingStockAtIndustries WHERE CarID = MyCarID)) THEN
            IF (MyTrainNumber NOT IN (SELECT TrainNumber FROM TrainCrews WHERE TrainNumber = MyTrainNumber)) THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Train is not crewed and cannot move.';
            ELSE
                INSERT INTO ConsistedCars VALUES (MyTrainNumber, MyCarID, DEFAULT);
                DELETE FROM RollingStockAtIndustries WHERE CarID = MyCarID;
            END IF;
        ELSE
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car is not available.';
    END CASE;
END$$
DELIMITER ;

#uspMoveCarFromTrainToYard(TrainNumber, 'CarID', 'YardName')
DROP PROCEDURE IF EXISTS uspMoveCarFromTrainToYard;
DELIMITER $$
CREATE PROCEDURE uspMoveCarFromTrainToYard (
    IN MyTrainNumber INT,
    IN MyCarID VARCHAR(255),
    IN MyYardName VARCHAR(255))
BEGIN
    CASE
        WHEN (MyTrainNumber NOT IN (SELECT TrainNumber FROM Trains WHERE TrainNumber = MyTrainNumber)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Train not found.';
        WHEN (MyCarID NOT IN (SELECT CarID FROM RollingStockCars WHERE CarID = MyCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car not found.';
        WHEN (MyCarID NOT IN (SELECT CarID FROM ConsistedCars WHERE TrainNumber = MyTrainNumber AND CarID = MyCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car is not in your train.';
        WHEN (MyYardName NOT IN (SELECT YardName FROM Yards WHERE YardName = MyYardName)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Yard does not exist.';
        WHEN ((SELECT ModuleName FROM TrainLocations WHERE TrainNumber = MyTrainNumber)
                <> (SELECT ModuleName FROM Yards WHERE YardName = MyYardName)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Train cannot drop off car at the yard from this location.';
        ELSE
            DELETE FROM ConsistedCars WHERE TrainNumber = MyTrainNumber AND CarID = MyCarID;
            INSERT INTO RollingStockAtYards VALUES (MyCarID, MyYardName, DEFAULT);
    END CASE;
END$$
DELIMITER ;

#uspMoveCarFromTrainToIndustry(TrainNumber, 'CarID', 'IndustryName', SidingNumber)
DROP PROCEDURE IF EXISTS uspMoveCarFromTrainToIndustry;
DELIMITER $$
CREATE PROCEDURE uspMoveCarFromTrainToIndustry (
    IN MyTrainNumber INT,
    IN MyCarID VARCHAR(255),
    IN MyIndustryName VARCHAR(255),
    IN MySidingNumber INT)
BEGIN
    CASE
        WHEN (MyTrainNumber NOT IN (SELECT TrainNumber FROM Trains WHERE TrainNumber = MyTrainNumber)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Train not found.';
        WHEN (MyCarID NOT IN (SELECT CarID FROM RollingStockCars WHERE CarID = MyCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car not found.';
        WHEN (MyCarID NOT IN (SELECT CarID FROM ConsistedCars WHERE TrainNumber = MyTrainNumber AND CarID = MyCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car is not in your train.';
        WHEN (MyIndustryName NOT IN (SELECT IndustryName FROM IndustriesAvailable WHERE IndustryName = MyIndustryName)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Industry does not exist or is not available.';
        WHEN (MySidingNumber NOT IN (SELECT SidingNumber FROM IndustrySidings WHERE IndustryName = MyIndustryName AND SidingNumber = MySidingNumber)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Siding does not exist at this industry.';
        WHEN (MyTrainNumber NOT IN (SELECT TrainNumber FROM TrainCrews WHERE TrainNumber = MyTrainNumber)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Train is not crewed and cannot move.';
        WHEN ((SELECT ModuleName FROM TrainLocations WHERE TrainNumber = MyTrainNumber)
                <> (SELECT ModuleName FROM Industries WHERE IndustryName = MyIndustryName)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Train cannot drop off car at the industry from this location.';
        ELSE
            DELETE FROM ConsistedCars WHERE TrainNumber = MyTrainNumber and CarID = MyCarID;
            INSERT INTO RollingStockAtIndustries VALUES (MyCarID, MyIndustryName, MySidingNumber, DEFAULT);
    END CASE;
END$$
DELIMITER ;

#uspServiceIndustry('CarID')
DROP PROCEDURE IF EXISTS uspServiceIndustry;
DELIMITER $$
CREATE PROCEDURE uspServiceIndustry (
    IN MyCarID VARCHAR(255))
BEGIN
    DECLARE MyShipmentID INT;
    DECLARE MyShipmentLoaded BOOL;
    DECLARE MyShipmentUnloaded BOOL;
    DECLARE MyProductTypeName VARCHAR(255);
    DECLARE MyFromIndustry VARCHAR(255);
    DECLARE MyToIndustry VARCHAR(255);

    DECLARE MyIndustryName VARCHAR(255);
    DECLARE MySidingNumber INT;
    DECLARE ServiceableCarSiding BOOL;
    
    DECLARE MyCarLength INT;
    DECLARE MyFromSiding INT;
    
    CASE
        WHEN (MyCarID NOT IN (SELECT CarID FROM RollingStockCars WHERE CarID = MyCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car not found.';
        WHEN (MyCarID NOT IN (SELECT CarID FROM Waybills WHERE CarID = MyCarID)) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Car not in service.';
        WHEN (MyCarID NOT IN (SELECT CarID FROM RollingStockAtIndustries WHERE CarID = MyCarID)) THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Car is not at an industry.';
        ELSE
            #check if car is at correct industry and siding for associated product types.  if not, fail.
            SET MyShipmentID = (SELECT ShipmentID
                FROM Waybills
                WHERE CarID = MyCarID);
            SET MyShipmentLoaded = (MyShipmentID IN (SELECT ShipmentID
                FROM ShipmentsLoaded
                WHERE ShipmentID = MyShipmentID));
            SET MyShipmentUnloaded = (MyShipmentID IN (SELECT ShipmentID
                FROM ShipmentsUnloaded
                WHERE ShipmentID = MyShipmentID));

            SET MyProductTypeName = (SELECT ProductTypeName
                FROM Shipments
                WHERE ShipmentID = MyShipmentID);
            SET MyFromIndustry = (SELECT FromIndustry
                FROM Shipments
                WHERE ShipmentID = MyShipmentID);
            SET MyToIndustry = (SELECT ToIndustry
                FROM Shipments
                WHERE ShipmentID = MyShipmentID);
            
            SET MyIndustryName = (SELECT IndustryName
                FROM RollingStockAtIndustries
                WHERE CarID = MyCarID);
            SET MySidingNumber = (SELECT SidingNumber
                FROM RollingStockAtIndustries
                WHERE CarID = MyCarID);
            SET ServiceableCarSiding = ufnCheckServiceableCarSiding(MyProductTypeName, MyIndustryName, MySidingNumber);
            
            IF (MyIndustryName = MyFromIndustry AND NOT MyShipmentLoaded) THEN
                #do loading stuff
                IF (ServiceableCarSiding) THEN
                    INSERT INTO ShipmentsLoaded VALUES (MyShipmentID, DEFAULT);
                    
                    SET MyCarLength = (SELECT CarLength
                        FROM RollingStockTypes
                        WHERE CarTypeName = (SELECT CarTypeName
                            FROM RollingStockCars
                            WHERE CarID = MyCarID));
                    SET MyFromSiding = (SELECT FromSiding
                        FROM Shipments
                        WHERE ShipmentID = MyShipmentID);
                    UPDATE IndustrySidings SET AvailableLength = AvailableLength + MyCarLength WHERE IndustryName = MyFromIndustry AND SidingNumber = MyFromSiding;
                ELSE
                    SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Cannot load car at this siding.';
                END IF;
            ELSEIF (MyIndustryName = MyToIndustry AND MyShipmentLoaded AND NOT MyShipmentUnloaded) THEN
                #do unloading stuff
                IF (ServiceableCarSiding) THEN
                    INSERT INTO ShipmentsUnloaded VALUES (MyShipmentID, DEFAULT);
                ELSE
                    SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Cannot unload car at this siding.';
                END IF;
            ELSE
                #fail
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'This industry has no shipments for this car.';
            END IF;
    END CASE;
END$$
DELIMITER ;