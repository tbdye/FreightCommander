#Test uspAddTrain(TrainNumber, LeadPower, DCCAddress, 'ModuleName')
    CALL uspAddTrain(1, 1234, 1234, 'Black River Yard');
    CALL uspAddTrain(2, 2345, 2345, 'Black River Yard');
    CALL uspAddTrain(1, 1234, 1234, 'Black River Yard'); -- Train already exists.
    CALL uspAddTrain(3, 2345, 2345, 'Unknown'); -- Location does not exist or is not active.
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE Trains;
    TRUNCATE TABLE TrainLocations;
    SET FOREIGN_KEY_CHECKS = 1;

#Test uspRemoveTrain(TrainNumber)
    INSERT INTO Trains VALUES (1, 1234, 1234, DEFAULT);
    INSERT INTO Trains VALUES (2, 2345, 2345, DEFAULT);
    INSERT INTO Trains VALUES (3, 3456, 3456, DEFAULT);
    CALL uspRemoveTrain(1);
    CALL uspRemoveTrain(2);
    CALL uspRemoveTrain(99); -- Train not found.
    INSERT INTO RollingStockCars VALUES ('AA', 'Box Car');
    INSERT INTO ConsistedCars VALUES (3, 'AA', DEFAULT);
    CALL uspRemoveTrain(3); -- Train has remaining consisted cars.
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE Trains;
    TRUNCATE TABLE RollingStockCars;
    TRUNCATE TABLE ConsistedCars;
    SET FOREIGN_KEY_CHECKS = 1;

#Test uspModifyTrain(TrainNumber, LeadPower, DCCAddress)
    INSERT INTO Trains VALUES (1, 1111, 1111, DEFAULT);
    INSERT INTO Trains VALUES (2, 2222, 2222, DEFAULT);
    CALL uspModifyTrain(1, 1234, 1234);
    CALL uspModifyTrain(2, 2345, 2345);
    CALL uspModifyTrain(99, 9999, 9999); -- Train not found.
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE Trains;
    SET FOREIGN_KEY_CHECKS = 1;

#Test uspAddCarToGame('CarID', 'CarTypeName', 'YardName')
    CALL uspAddCarToGame('AA', 'Box Car', 'Black River Yard');
    CALL uspAddCarToGame('BB', 'Box Car', 'Black River Yard');
    CALL uspAddCarToGame('BB', 'Box Car', 'Black River Yard'); -- Car already exists.
    CALL uspAddCarToGame('CC', 'Unknown', 'Black River Yard'); -- Car type does not exist.
    CALL uspAddCarToGame('CC', 'Box Car', 'Unknown'); -- Yard does not exist.
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE RollingStockCars;
    TRUNCATE TABLE RollingStockAtYards;
    SET FOREIGN_KEY_CHECKS = 1;

#Test uspRemoveCarFromGame('CarID')
    INSERT INTO RollingStockCars VALUES ('AA', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('BB', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('CC', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('DD', 'Reefer');
    CALL uspRemoveCarFromGame('AA');
    CALL uspRemoveCarFromGame('BB');
    CALL uspRemoveCarFromGame('XX'); -- Car not found.
    INSERT INTO Trains VALUES (1, 1234, 1234, DEFAULT);
    INSERT INTO ConsistedCars VALUES (1, 'CC', DEFAULT);
    CALL uspRemoveCarFromGame('CC'); -- Car is consisted to a train and cannot be removed.
    INSERT INTO Shipments VALUES (DEFAULT, 'Dairy', 'Half Circle Farms', 1, 'MMI Transfer Site 3', 1, DEFAULT);
    INSERT INTO Waybills VALUES ('DD', LAST_INSERT_ID(), 'Black River Yard');
    CALL uspRemoveCarFromGame('DD'); -- Car has existing waybill and cannot be removed.
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE RollingStockCars;
    TRUNCATE TABLE Trains;
    TRUNCATE TABLE ConsistedCars;
    TRUNCATE TABLE Shipments;
    TRUNCATE TABLE Waybills;
    SET FOREIGN_KEY_CHECKS = 1;

#Test ufnGetProductType('CarTypeName')
    SELECT ufnGetProductType('Box Car');

#Test ufnGetProducingIndustry(CarLength, 'ProductTypeName')
    SELECT ufnGetProducingIndustry(75, 'Garbage');

#Test ufnGetConsumingIndustry(CarLength, 'ProductTypeName')
    SELECT ufnGetConsumingIndustry(65, 'Crates');

#Test ufnGetIndustrySiding('IndustryName', 'ProductTypeName')
    SELECT ufnGetIndustrySiding('MMI Transfer Site 3', 'Dairy'), ufnGetIndustrySiding('MMI Transfer Site 3', 'General Merchandise');

#Test uspAddCarToService('CarID')
    INSERT INTO RollingStockCars VALUES ('AA', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('BB', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('CC', 'Wood Chip Car');
    INSERT INTO RollingStockCars VALUES ('DD', 'Stock Car');
    INSERT INTO RollingStockCars VALUES ('EE', 'Stock Car');
    CALL uspAddCarToService('AA');
    SET @AAfromIndustry = (SELECT FromIndustry FROM Shipments WHERE ShipmentID = (SELECT ShipmentID FROM Waybills WHERE CarID = 'AA'));
    SET @AAfromSiding = (SELECT FromSiding FROM Shipments WHERE ShipmentID = (SELECT ShipmentID FROM Waybills WHERE CarID = 'AA'));
    CALL uspAddCarToService('BB');
    SET @BBfromIndustry = (SELECT FromIndustry FROM Shipments WHERE ShipmentID = (SELECT ShipmentID FROM Waybills WHERE CarID = 'BB'));
    SET @BBfromSiding = (SELECT FromSiding FROM Shipments WHERE ShipmentID = (SELECT ShipmentID FROM Waybills WHERE CarID = 'BB'));
    CALL uspAddCarToService('XX'); -- Car not found.
    CALL uspAddCarToService('BB'); -- Car already in service.
    CALL uspAddCarToService('CC'); -- No industry orders for this car type on this layout.
    CALL uspAddCarToService('DD');
    SET @DDfromIndustry = (SELECT FromIndustry FROM Shipments WHERE ShipmentID = (SELECT ShipmentID FROM Waybills WHERE CarID = 'DD'));
    SET @DDfromSiding = (SELECT FromSiding FROM Shipments WHERE ShipmentID = (SELECT ShipmentID FROM Waybills WHERE CarID = 'DD'));
    UPDATE IndustrySidings SET AvailableLength = 0 WHERE IndustryName = 'Half Circle Farms' AND SidingNumber = 1;
    CALL uspAddCarToService('EE'); -- No industry orders at this time.
    UPDATE IndustrySidings SET AvailableLength = 600 WHERE IndustryName = 'Half Circle Farms' AND SidingNumber = 1;
    UPDATE IndustrySidings SET AvailableLength = 0 WHERE IndustryName = 'Palin Interchange' AND SidingNumber = 1;
    CALL uspAddCarToService('EE'); -- No industry orders at this time.
    UPDATE IndustrySidings SET AvailableLength = 500 WHERE IndustryName = 'Palin Interchange' AND SidingNumber = 1;
    SET SQL_SAFE_UPDATES = 0;
    SET @AAlength = (SELECT SidingLength FROM IndustrySidings WHERE IndustryName = @AAfromIndustry AND SidingNumber = @AAfromSiding);
    SET @BBlength = (SELECT SidingLength FROM IndustrySidings WHERE IndustryName = @BBfromIndustry AND SidingNumber = @BBfromSiding);
    SET @DDlength = (SELECT SidingLength FROM IndustrySidings WHERE IndustryName = @DDfromIndustry AND SidingNumber = @DDfromSiding);
    UPDATE IndustrySidings SET AvailableLength = @AAlength WHERE IndustryName = @AAfromIndustry AND SidingNumber = @AAfromSiding;
    UPDATE IndustrySidings SET AvailableLength = @BBlength WHERE IndustryName = @BBfromIndustry AND SidingNumber = @BBfromSiding;
    UPDATE IndustrySidings SET AvailableLength = @DDlength WHERE IndustryName = @DDfromIndustry AND SidingNumber = @DDfromSiding;
    SET SQL_SAFE_UPDATES = 1;
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE RollingStockCars;
    TRUNCATE TABLE Shipments;
    TRUNCATE TABLE Waybills;
    SET FOREIGN_KEY_CHECKS = 1;
    SET @AAfromIndustry = NULL;
    SET @BBfromIndustry = NULL;
    SET @DDfromIndustry = NULL;
    SET @AAfromSiding = NULL;
    SET @BBfromSiding = NULL;
    SET @DDfromSiding = NULL;
    SET @AAlength = NULL;
    SET @BBlength = NULL;
    SET @DDlength = NULL;

#Test uspRemoveCarFromService('CarID')
    INSERT INTO RollingStockCars VALUES ('AA', 'Reefer');
    INSERT INTO RollingStockCars VALUES ('BB', 'Reefer');
    INSERT INTO Shipments VALUES (DEFAULT, 'Dairy', 'Half Circle Farms', 1, 'MMI Transfer Site 3', 1, DEFAULT);
    INSERT INTO Waybills VALUES ('AA', LAST_INSERT_ID(), 'Black River Yard');
    INSERT INTO Shipments VALUES (DEFAULT, 'Dairy', 'Half Circle Farms', 1, 'MMI Transfer Site 3', 1, DEFAULT);
    INSERT INTO Waybills VALUES ('BB', LAST_INSERT_ID(), 'Black River Yard');
    UPDATE IndustrySidings SET AvailableLength = 470 WHERE IndustryName = 'Half Circle Farms' AND SidingNumber = 1;
    CALL uspRemoveCarFromService('AA');
    CALL uspRemoveCarFromService('BB');

    CALL uspRemoveCarFromService('XX'); -- Car not found.
    CALL uspRemoveCarFromService('BB'); -- Car not in service.

    INSERT INTO RollingStockCars VALUES ('CC', 'Reefer');
    INSERT INTO Shipments VALUES (DEFAULT, 'Dairy', 'Half Circle Farms', 1, 'MMI Transfer Site 3', 1, DEFAULT);
    INSERT INTO Waybills VALUES ('CC', LAST_INSERT_ID(), 'Black River Yard');
    SET @shippingNo = (SELECT ShipmentID FROM Waybills WHERE CarID = 'CC');
    INSERT INTO ShipmentsLoaded VALUES (@shippingNo, DEFAULT);
    CALL uspRemoveCarFromService('CC'); -- Car has open waybill and cannot be removed.

    INSERT INTO ShipmentsUnloaded VALUES (@shippingNo, DEFAULT);
    CALL uspRemoveCarFromService('CC');

    INSERT INTO RollingStockCars VALUES ('DD', 'Reefer');
    INSERT INTO Shipments VALUES (DEFAULT, 'Dairy', 'Half Circle Farms', 1, 'MMI Transfer Site 3', 1, DEFAULT);
    INSERT INTO Waybills VALUES ('DD', LAST_INSERT_ID(), 'Black River Yard');
    UPDATE IndustrySidings SET AvailableLength = 535 WHERE IndustryName = 'Half Circle Farms' AND SidingNumber = 1;
    CALL uspRemoveCarFromService('DD');

    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE RollingStockCars;
    TRUNCATE TABLE Shipments;
    TRUNCATE TABLE Waybills;
    TRUNCATE TABLE ShipmentsLoaded;
    TRUNCATE TABLE ShipmentsUnloaded;
    SET FOREIGN_KEY_CHECKS = 1;
    SET @shippingNo = NULL;

#Test uspModifyCarInService('OldCarID', 'NewCarID')
    INSERT INTO RollingStockCars VALUES ('AA', 'Reefer');
    INSERT INTO RollingStockCars VALUES ('BB', 'Reefer');
    INSERT INTO RollingStockCars VALUES ('CC', 'Reefer');
    INSERT INTO RollingStockCars VALUES ('DD', 'Wood Chip Car');
    INSERT INTO Shipments VALUES (DEFAULT, 'Dairy', 'Half Circle Farms', 1, 'MMI Transfer Site 3', 1, DEFAULT);
    INSERT INTO Waybills VALUES ('AA', LAST_INSERT_ID(), 'Black River Yard');
    INSERT INTO Shipments VALUES (DEFAULT, 'Dairy', 'Half Circle Farms', 1, 'MMI Transfer Site 3', 1, DEFAULT);
    INSERT INTO Waybills VALUES ('BB', LAST_INSERT_ID(), 'Black River Yard');
    CALL uspModifyCarInService('BB', 'CC');
    CALL uspModifyCarInService('AA', 'BB');
    CALL uspModifyCarInService('XX', 'AA'); -- Originating car not found.
    CALL uspModifyCarInService('BB', 'XX'); -- Replacement car not found.
    CALL uspModifyCarInService('BB', 'BB'); -- Replacement car has existing waybill.
    CALL uspModifyCarInService('BB', 'CC'); -- Replacement car has existing waybill.
    CALL uspModifyCarInService('BB', 'DD'); -- Replacement car type does not match original car type.
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE RollingStockCars;
    TRUNCATE TABLE Shipments;
    TRUNCATE TABLE Waybills;
    SET FOREIGN_KEY_CHECKS = 1;

#Test uspAddCrewToTrain(TrainNumber, 'CrewName')
    INSERT INTO Trains VALUES (1, 1234, 1234, DEFAULT);
    INSERT INTO Trains VALUES (2, 2345, 2345, DEFAULT);
    INSERT INTO Trains VALUES (3, 3456, 3456, DEFAULT);
    CALL uspAddCrewToTrain(1, 'Player 1');
    CALL uspAddCrewToTrain(2, 'Player 2');
    CALL uspAddCrewToTrain(99, 'Player 3'); -- Train not found.
    CALL uspAddCrewToTrain(3, 'Player 1'); -- Crew already assigned to another train.
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE Trains;
    TRUNCATE TABLE TrainCrews;
    SET FOREIGN_KEY_CHECKS = 1;

#Test uspRemoveCrewFromTrain(TrainNumber)
    INSERT INTO Trains VALUES (1, 1234, 1234, DEFAULT);
    INSERT INTO Trains VALUES (2, 2345, 2345, DEFAULT);
    INSERT INTO TrainCrews VALUES (1, 'Player 1', DEFAULT);
    INSERT INTO TrainCrews VALUES (2, 'Player 2', DEFAULT);
    CALL uspRemoveCrewFromTrain(1);
    CALL uspRemoveCrewFromTrain(2);
    CALL uspRemoveCrewFromTrain(99); -- Train not found.
    CALL uspRemoveCrewFromTrain(2); -- Train not assigned a crew.
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE Trains;
    TRUNCATE TABLE TrainCrews;
    SET FOREIGN_KEY_CHECKS = 1;

#Test uspMoveTrain(TrainNumber, 'ModuleName')
    INSERT INTO Trains VALUES (1, 1234, 1234, DEFAULT);
    INSERT INTO Trains VALUES (2, 2345, 2345, DEFAULT);
    INSERT INTO TrainLocations VALUES (1, 'Black River Yard', DEFAULT);
    INSERT INTO TrainLocations VALUES (2, 'Black River Yard', DEFAULT);
    INSERT INTO TrainCrews VALUES (1, 'Player 1', DEFAULT);
    CALL uspMoveTrain(1, 'Chesterfield');
    CALL uspMoveTrain(1, '180 Farms');
    CALL uspMoveTrain(99, 'Chesterfield'); -- Train not found.
    CALL uspMoveTrain(1, 'Unknown'); -- Location does not exist or is not active.
    CALL uspMoveTrain(2, 'Chesterfield'); -- Train is not crewed and cannot move.
    CALL uspMoveTrain(1, '180 Farms'); -- Train was already at that location.
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE Trains;
    TRUNCATE TABLE TrainLocations;
    TRUNCATE TABLE TrainCrews;
    SET FOREIGN_KEY_CHECKS = 1;

#Test ufnGetCarModuleName('CarID')
    INSERT INTO RollingStockCars VALUES ('AA', 'Box Car'); -- 180 Farms
    INSERT INTO RollingStockCars VALUES ('BB', 'Box Car'); -- Black River Yard
    INSERT INTO RollingStockCars VALUES ('CC', 'Box Car'); -- Chesterfield
    INSERT INTO RollingStockCars VALUES ('DD', 'Box Car'); -- NULL
    INSERT INTO Trains VALUES (1, 1234, 1234, DEFAULT);
    INSERT INTO TrainLocations VALUES (1, '180 Farms', DEFAULT);
    INSERT INTO ConsistedCars VALUES (1, 'AA', DEFAULT);
    INSERT INTO RollingStockAtYards VALUES ('BB', 'Black River Yard', DEFAULT);
    INSERT INTO RollingStockAtIndustries VALUES ('CC', 'Cobra Golf', 1, DEFAULT);
    SELECT ufnGetCarModuleName('AA'), ufnGetCarModuleName('BB'), ufnGetCarModuleName('CC'), ufnGetCarModuleName('DD');
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE RollingStockCars;
    TRUNCATE TABLE Trains;
    TRUNCATE TABLE TrainLocations;
    TRUNCATE TABLE ConsistedCars;
    TRUNCATE TABLE RollingStockAtYards;
    TRUNCATE TABLE RollingStockAtIndustries;
    SET FOREIGN_KEY_CHECKS = 1;

#Test uspMoveCarToTrain(TrainNumber, 'CarID')
    INSERT INTO RollingStockCars VALUES ('AA', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('BB', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('CC', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('DD', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('EE', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('FF', 'Box Car');
    INSERT INTO Trains VALUES (1, 1234, 1234, DEFAULT);
    INSERT INTO Trains VALUES (2, 2345, 2345, DEFAULT);
    INSERT INTO TrainLocations VALUES (1, 'Black River Yard', DEFAULT);
    INSERT INTO TrainLocations VALUES (2, 'Black River Yard', DEFAULT);
    INSERT INTO TrainCrews VALUES (1, 'Player 1', DEFAULT);
    INSERT INTO RollingStockAtYards VALUES ('AA', 'Black River Yard', DEFAULT);
    INSERT INTO RollingStockAtIndustries VALUES ('BB', 'MMI Transfer Site 3', 1, DEFAULT);
    INSERT INTO RollingStockAtIndustries VALUES ('CC', 'MMI Transfer Site 3', 2, DEFAULT);
    INSERT INTO ConsistedCars VALUES (2, 'DD', DEFAULT);
    INSERT INTO RollingStockAtIndustries VALUES ('EE', 'Cobra Golf', 1, DEFAULT);
    CALL uspMoveCarToTrain(1, 'AA');
    CALL uspMoveCarToTrain(1, 'BB');
    CALL uspMoveCarToTrain(99, 'CC'); -- Train not found.
    CALL uspMoveCarToTrain(1, 'XX'); -- Car not found.
    CALL uspMoveCarToTrain(1, 'AA'); -- Car is already in your train.
    CALL uspMoveCarToTrain(1, 'DD'); -- Car is still consisted to another train.
    CALL uspMoveCarToTrain(1, 'EE'); -- Car is not in the same location as the train.
    UPDATE TrainLocations SET ModuleName = 'Chesterfield' WHERE TrainNumber = 2;
    CALL uspMoveCarToTrain(2, 'EE'); -- Train is not crewed and cannot move.
    CALL uspMoveCarToTrain(1, 'FF'); -- Car is not available.
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE RollingStockCars;
    TRUNCATE TABLE Trains;
    TRUNCATE TABLE TrainLocations;
    TRUNCATE TABLE TrainCrews;
    TRUNCATE TABLE RollingStockAtYards;
    TRUNCATE TABLE RollingStockAtIndustries;
    TRUNCATE TABLE ConsistedCars;
    SET FOREIGN_KEY_CHECKS = 1;

#Test uspMoveCarFromTrainToYard(TrainNumber, 'CarID', 'YardName')
    INSERT INTO RollingStockCars VALUES ('AA', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('BB', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('CC', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('DD', 'Box Car');
    INSERT INTO Trains VALUES (1, 1234, 1234, DEFAULT);
    INSERT INTO Trains VALUES (2, 2345, 2345, DEFAULT);
    INSERT INTO TrainLocations VALUES (1, 'Black River Yard', DEFAULT);
    INSERT INTO TrainLocations VALUES (2, 'Black River Yard', DEFAULT);
    INSERT INTO ConsistedCars VALUES (1, 'AA', DEFAULT);
    INSERT INTO ConsistedCars VALUES (1, 'BB', DEFAULT);
    INSERT INTO ConsistedCars VALUES (1, 'CC', DEFAULT);
    INSERT INTO ConsistedCars VALUES (2, 'DD', DEFAULT);
    CALL uspMoveCarFromTrainToYard(1, 'AA', 'Black River Yard');
    CALL uspMoveCarFromTrainToYard(1, 'BB', 'Black River Yard');
    CALL uspMoveCarFromTrainToYard(99, 'CC', 'Black River Yard'); -- Train not found.
    CALL uspMoveCarFromTrainToYard(1, 'XX', 'Black River Yard'); -- Car not found.
    CALL uspMoveCarFromTrainToYard(1, 'BB', 'Black River Yard'); -- Car is not in your train.
    CALL uspMoveCarFromTrainToYard(1, 'DD', 'Black River Yard'); -- Car is not in your train.
    CALL uspMoveCarFromTrainToYard(1, 'CC', 'Unknown'); -- Yard does not exist.
    UPDATE TrainLocations SET ModuleName = 'Chesterfield' WHERE TrainNumber = 1;
    CALL uspMoveCarFromTrainToYard(1, 'CC', 'Black River Yard'); -- Train cannot drop off car at the yard from this location.
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE RollingStockCars;
    TRUNCATE TABLE Trains;
    TRUNCATE TABLE TrainLocations;
    TRUNCATE TABLE ConsistedCars;
    TRUNCATE TABLE RollingStockAtYards;
    SET FOREIGN_KEY_CHECKS = 1;

#Test uspMoveCarFromTrainToIndustry(TrainNumber, 'CarID', 'IndustryName', SidingNumber)
    INSERT INTO RollingStockCars VALUES ('AA', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('BB', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('CC', 'Box Car');
    INSERT INTO RollingStockCars VALUES ('DD', 'Box Car');
    INSERT INTO Trains VALUES (1, 1234, 1234, DEFAULT);
    INSERT INTO Trains VALUES (2, 2345, 2345, DEFAULT);
    INSERT INTO TrainLocations VALUES (1, 'Black River Yard', DEFAULT);
    INSERT INTO TrainLocations VALUES (2, 'Black River Yard', DEFAULT);
    INSERT INTO TrainCrews VALUES (1, 'Player 1', DEFAULT);
    INSERT INTO ConsistedCars VALUES (1, 'AA', DEFAULT);
    INSERT INTO ConsistedCars VALUES (1, 'BB', DEFAULT);
    INSERT INTO ConsistedCars VALUES (1, 'CC', DEFAULT);
    INSERT INTO ConsistedCars VALUES (2, 'DD', DEFAULT);
    CALL uspMoveCarFromTrainToIndustry(1, 'AA', 'MMI Transfer Site 3', 1);
    CALL uspMoveCarFromTrainToIndustry(1, 'BB', 'MMI Transfer Site 3', 2);
    CALL uspMoveCarFromTrainToIndustry(99, 'CC', 'MMI Transfer Site 3', 1); -- Train not found.
    CALL uspMoveCarFromTrainToIndustry(1, 'XX', 'MMI Transfer Site 3', 1); -- Car not found.
    CALL uspMoveCarFromTrainToIndustry(1, 'BB', 'MMI Transfer Site 3', 2); -- Car is not in your train.
    CALL uspMoveCarFromTrainToIndustry(1, 'DD', 'MMI Transfer Site 3', 2); -- Car is not in your train.
    CALL uspMoveCarFromTrainToIndustry(1, 'CC', 'Unknown', 1); -- Industry does not exist or is not available.
    CALL uspMoveCarFromTrainToIndustry(1, 'CC', 'MMI Transfer Site 3', 99); -- Siding does not exist at this industry.
    CALL uspMoveCarFromTrainToIndustry(2, 'DD', 'MMI Transfer Site 3', 1); -- Train is not crewed and cannot move.
    CALL uspMoveCarFromTrainToIndustry(1, 'CC', 'Cobra Golf', 1); -- Train cannot drop off car at the industry from this location.
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE RollingStockCars;
    TRUNCATE TABLE Trains;
    TRUNCATE TABLE TrainLocations;
    TRUNCATE TABLE TrainCrews;
    TRUNCATE TABLE ConsistedCars;
    TRUNCATE TABLE RollingStockAtIndustries;
    SET FOREIGN_KEY_CHECKS = 1;

#Test ufnCheckServiceableCarSiding('ProductTypeName', 'IndustryName', SidingNumber)
    SELECT ufnCheckServiceableCarSiding('Dairy', 'MMI Transfer Site 3', 2), ufnCheckServiceableCarSiding('Dairy', 'MMI Transfer Site 3', 3);

#Test uspServiceIndustry('CarID')
    INSERT INTO RollingStockCars VALUES ('AA', 'Reefer');
    INSERT INTO RollingStockCars VALUES ('BB', 'Reefer');
    INSERT INTO Shipments VALUES (DEFAULT, 'Dairy', 'Half Circle Farms', 1, 'MMI Transfer Site 3', 1, DEFAULT);
    INSERT INTO Waybills VALUES ('AA', LAST_INSERT_ID(), 'Black River Yard');
    INSERT INTO Shipments VALUES (DEFAULT, 'Dairy', 'Half Circle Farms', 1, 'MMI Transfer Site 3', 2, DEFAULT);
    INSERT INTO Waybills VALUES ('BB', LAST_INSERT_ID(), 'Black River Yard');
    INSERT INTO RollingStockAtIndustries VALUES ('AA', 'Half Circle Farms', 1, DEFAULT);
    INSERT INTO RollingStockAtIndustries VALUES ('BB', 'Half Circle Farms', 1, DEFAULT);
    UPDATE IndustrySidings SET AvailableLength = 470 WHERE IndustryName = 'Half Circle Farms' AND SidingNumber = 1;
    CALL uspServiceIndustry('AA');
    CALL uspServiceIndustry('BB');
    CALL uspServiceIndustry('BB'); -- This industry has no shipments for this car.
    DELETE FROM RollingStockAtIndustries WHERE CarID = 'AA';
    DELETE FROM RollingStockAtIndustries WHERE CarID = 'BB';
    INSERT INTO RollingStockAtIndustries VALUES ('AA', 'MMI Transfer Site 3', 1, DEFAULT);
    INSERT INTO RollingStockAtIndustries VALUES ('BB', 'MMI Transfer Site 3', 2, DEFAULT);
    CALL uspServiceIndustry('BB');
    CALL uspServiceIndustry('AA');
    CALL uspServiceIndustry('AA'); -- This industry has no shipments for this car.

    INSERT INTO RollingStockCars VALUES ('CC', 'Box Car');
    INSERT INTO Shipments VALUES (DEFAULT, 'Crates', 'Bauxen Crates', 3, 'Cobra Golf', 1, DEFAULT);
    INSERT INTO Waybills VALUES ('CC', LAST_INSERT_ID(), 'Black River Yard');
    INSERT INTO RollingStockAtIndustries VALUES ('CC', 'Bauxen Crates', 4, DEFAULT);
    UPDATE IndustrySidings SET AvailableLength = 85 WHERE IndustryName = 'Bauxen Crates' AND SidingNumber = 3;
    CALL uspServiceIndustry('CC');

    INSERT INTO RollingStockCars VALUES ('DD', 'Box Car');
    INSERT INTO Shipments VALUES (DEFAULT, 'Dairy', 'Half Circle Farms', 1, 'MMI Transfer Site 3', 2, DEFAULT);
    SET @DDshipID = LAST_INSERT_ID();
    INSERT INTO Waybills VALUES ('DD', @DDshipID, 'Black River Yard');
    INSERT INTO ShipmentsLoaded VALUES (@DDshipID, DEFAULT);
    INSERT INTO RollingStockAtIndustries VALUES ('DD', 'MMI Transfer Site 3', 1, DEFAULT);
    CALL uspServiceIndustry('DD');

    CALL uspServiceIndustry('XX'); -- Car not found.

    INSERT INTO RollingStockCars VALUES ('EE', 'Long Hopper');
    CALL uspServiceIndustry('EE'); -- Car not in service.

    INSERT INTO Shipments VALUES (DEFAULT, 'Grain', 'Oatus Elevator', 1, 'Palin Interchange', 1, DEFAULT);
    INSERT INTO Waybills VALUES ('EE', LAST_INSERT_ID(), 'Black River Yard');
    CALL uspServiceIndustry('EE'); -- Car is not at an industry.

    INSERT INTO RollingStockCars VALUES ('FF', 'Box Car');
    INSERT INTO Shipments VALUES (DEFAULT, 'Dairy', 'Half Circle Farms', 1, 'MMI Transfer Site 3', 2, DEFAULT);
    INSERT INTO Waybills VALUES ('FF', LAST_INSERT_ID(), 'Black River Yard');
    INSERT INTO RollingStockAtIndustries VALUES ('FF', 'MMI Transfer Site 3', 1, DEFAULT);
    CALL uspServiceIndustry('FF'); -- This industry has no shipments for this car.
    INSERT INTO IndustryProducts VALUES ('Palin Interchange', 'Dairy', FALSE);
    DELETE FROM RollingStockAtIndustries WHERE CarID = 'FF';
    INSERT INTO RollingStockAtIndustries VALUES ('FF', 'Palin Interchange', 1, DEFAULT);
    CALL uspServiceIndustry('FF'); -- This industry has no shipments for this car.
    DELETE FROM IndustryProducts WHERE IndustryName = 'Palin Interchange' AND ProductTypeName = 'Dairy';

    INSERT INTO RollingStockCars VALUES ('GG', 'Gondola');
    INSERT INTO IndustryProducts VALUES ('Pure Oil', 'Scrap Metal', FALSE);
    INSERT INTO Shipments VALUES (DEFAULT, 'Scrap Metal', 'B.R. Engine House', 1, 'Pure Oil', 4, DEFAULT);
    INSERT INTO Waybills VALUES ('GG', LAST_INSERT_ID(), 'Black River Yard');
    INSERT INTO RollingStockAtIndustries VALUES ('GG', 'B.R. Engine House', 3, DEFAULT);
    CALL uspServiceIndustry('GG'); -- Cannot load car at this siding.
    DELETE FROM IndustryProducts WHERE IndustryName = 'Pure Oil' AND ProductTypeName = 'Scrap Metal';

    INSERT INTO RollingStockCars VALUES ('HH', 'Box Car');
    INSERT INTO Shipments VALUES (DEFAULT, 'General Merchandise', 'Puget Warehouse', 1, 'MMI Transfer Site 3', 3, DEFAULT);
    SET @HHshipID = LAST_INSERT_ID();
    INSERT INTO Waybills VALUES ('HH', @HHshipID, 'Black River Yard');
    INSERT INTO ShipmentsLoaded VALUES (@HHshipID, DEFAULT);
    INSERT INTO RollingStockAtIndustries VALUES ('HH', 'MMI Transfer Site 3', 2, DEFAULT);
    CALL uspServiceIndustry('HH'); -- Cannot unload car at this siding.

    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE RollingStockCars;
    TRUNCATE TABLE Shipments;
    TRUNCATE TABLE Waybills;
    TRUNCATE TABLE RollingStockAtIndustries;
    TRUNCATE TABLE ShipmentsLoaded;
    TRUNCATE TABLE ShipmentsUnloaded;
    SET FOREIGN_KEY_CHECKS = 1;
    SET @DDshipID = NULL;
    SET @HHshipID = NULL;

#Test full session lifecycle
    CALL uspAddTrain(1, 1234, 1234, 'Black River Yard');
    CALL uspAddCarToGame('AA', 'Tank Car', 'Black River Yard');
    CALL uspAddCarToService('AA');

    CALL uspAddCrewToTrain(1, 'Player 1');
    CALL uspMoveCarToTrain(1, 'AA');
    SET @industry = (SELECT FromIndustry FROM Shipments WHERE ShipmentID = (SELECT ShipmentID FROM Waybills WHERE CarID = 'AA'));
    SET @siding = (SELECT FromSiding FROM Shipments WHERE ShipmentID = (SELECT ShipmentID FROM Waybills WHERE CarID = 'AA'));
    SET @module = (SELECT ModuleName FROM Industries WHERE IndustryName = @industry);
    CALL uspMoveTrain(1, @module);
    CALL uspMoveCarFromTrainToIndustry(1, 'AA', @industry, @siding);
    CALL uspServiceIndustry('AA');

    CALL uspMoveCarToTrain(1, 'AA');
    SET @industry = (SELECT ToIndustry FROM Shipments WHERE ShipmentID = (SELECT ShipmentID FROM Waybills WHERE CarID = 'AA'));
    SET @siding = (SELECT ToSiding FROM Shipments WHERE ShipmentID = (SELECT ShipmentID FROM Waybills WHERE CarID = 'AA'));
    SET @module = (SELECT ModuleName FROM Industries WHERE IndustryName = @industry);
    CALL uspMoveTrain(1, @module);
    CALL uspMoveCarFromTrainToIndustry(1, 'AA', @industry, @siding);
    CALL uspServiceIndustry('AA');

    CALL uspMoveCarToTrain(1, 'AA');
    SET @yard = (SELECT YardName FROM Waybills WHERE CarID = 'AA');
    SET @module = (SELECT ModuleName FROM Yards WHERE YardName = @yard);
    CALL uspMoveTrain(1, @module);
    CALL uspMoveCarFromTrainToYard(1, 'AA', @yard);
    CALL uspRemoveCrewFromTrain(1);
    CALL uspRemoveCarFromService('AA');
    CALL uspRemoveCarFromGame('AA');
    CALL uspRemoveTrain(1);

    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE Shipments;
    TRUNCATE TABLE ShipmentsLoaded;
    TRUNCATE TABLE ShipmentsUnloaded;
    SET FOREIGN_KEY_CHECKS = 1;
    SET @industry = NULL;
    SET @siding = NULL;
    SET @module = NULL;
    SET @yard = NULL;