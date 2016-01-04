#Clean up old data if any exists

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS ConsistedCars;
DROP TABLE IF EXISTS Industries;
DROP TABLE IF EXISTS IndustriesAvailable;
DROP TABLE IF EXISTS IndustryActivities;
DROP TABLE IF EXISTS IndustryProducts;
DROP TABLE IF EXISTS IndustrySidings;
DROP TABLE IF EXISTS Junctions;
DROP TABLE IF EXISTS MainLines;
DROP TABLE IF EXISTS Modules;
DROP TABLE IF EXISTS ModulesAvailable;
DROP TABLE IF EXISTS ProductTypes;
DROP TABLE IF EXISTS Regions;
DROP TABLE IF EXISTS RollingStockAtIndustries;
DROP TABLE IF EXISTS RollingStockAtYards;
DROP TABLE IF EXISTS RollingStockCars;
DROP TABLE IF EXISTS RollingStockTypes;
DROP TABLE IF EXISTS Shipments;
DROP TABLE IF EXISTS ShipmentsLoaded;
DROP TABLE IF EXISTS ShipmentsUnloaded;
DROP TABLE IF EXISTS SidingAssignments;
DROP TABLE IF EXISTS TrainCrews;
DROP TABLE IF EXISTS TrainLocations;
DROP TABLE IF EXISTS Trains;
DROP TABLE IF EXISTS Waybills;
DROP TABLE IF EXISTS Yards;
SET FOREIGN_KEY_CHECKS = 1;

#Build relational model

#Modules
#Defines properties of a physical space containing industries and railroad.
#Notes:  None.
#Pre-conditions:  None.
#Input Constraint:  N/A
#Constrains:  ModulesAvailable, Regions, MainLines, Junctions, Yards,
#	Industries, TrainLocations
CREATE TABLE Modules (
    ModuleName VARCHAR(255) NOT NULL PRIMARY KEY,
    ModuleOwner VARCHAR(255) NOT NULL,
    ModuleType VARCHAR(20),
    ModuleShape VARCHAR(20),
    Description VARCHAR(255)
);

#ModulesAvailable
#Defines the availability of a previously created module.
#Notes:  A module is available if it is part of a layout, but can remain
#	defined and not be available.
#Pre-conditions:  A valid Modules entity must exist.
#Input Constraint:  N/A
#Constrains:  None.
CREATE TABLE ModulesAvailable (
    ModuleName VARCHAR(255) NOT NULL PRIMARY KEY,
    IsAvailable BOOL NOT NULL,
    FOREIGN KEY (ModuleName)
        REFERENCES Modules (ModuleName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#Regions
#Defines groupings of modules and assigns a common name for the purpose of
#	layout maps.
#Notes:  Regions are used by a routing engine to indicate a path for a train to
#	follow (version 2.0).  They also provide information to the shipping order
#	generator to allow for physical layout spacing between load and unload
#	points (version 2.0).
#Pre-conditions:  A valid Modules entity must exist.
#Input Constraint:  N/A
#Constrains:  None.
CREATE TABLE Regions (
    RegionName VARCHAR(255) NOT NULL,
    ModuleName VARCHAR(255) NOT NULL,
    PRIMARY KEY (RegionName , ModuleName),
    FOREIGN KEY (ModuleName)
        REFERENCES Modules (ModuleName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#MainLines
#Defines a railroad track on a module that allows passage from at least one
#	side of a module.
#Notes:  A main line is contiguous if it allows through traffic to pass over
#	the entirety of a module.  Main lines are used by a routing engine and will
#	indicate a path for a train to follow (version 2.0).
#Pre-conditions:  A valid Modules entity must exist.
#Input Constraint:  N/A
#Constrains:  Junctions, Yards, Industries
CREATE TABLE MainLines (
    LineName VARCHAR(255) NOT NULL,
    ModuleName VARCHAR(255) NOT NULL,
    IsContiguous BOOL NOT NULL,
    PRIMARY KEY (LineName , ModuleName),
    FOREIGN KEY (ModuleName)
        REFERENCES Modules (ModuleName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#Junctions
#Defines a connection point between two main lines on a module where trains may
#	cross from one main line to another.
#Notes:  Physically, junctions are represented by turnouts, and are currently
#	non-directional in nature.  Junctions are used by a routing engine and will
#	indicate a path for a train to follow (version 2.0).
#Pre-conditions:  A valid Modules entity and two MainLines entities must exist.
#Input Constraint:  FromLine <> ToLine
#Constrains:  None.
CREATE TABLE Junctions (
    JunctionID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    ModuleName VARCHAR(255) NOT NULL,
    FromLine VARCHAR(255) NOT NULL,
    ToLine VARCHAR(255) NOT NULL,
    FOREIGN KEY (ModuleName)
        REFERENCES Modules (ModuleName)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (FromLine)
        REFERENCES MainLines (LineName)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ToLine)
        REFERENCES MainLines (LineName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#Junctions
#Trigger to ensure that FromLine and ToLine are not the same entities.
DELIMITER $$
CREATE TRIGGER JunctionsTrigger BEFORE INSERT ON Junctions
FOR EACH ROW
BEGIN
    IF (NEW.FromLine = NEW.ToLine) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A junction can only exist between two different main lines.';
    END IF;
END$$
DELIMITER ;

#RollingStockTypes
#Define a rolling stock car by name and length.
#Notes:  None.
#Pre-conditions:  None.
#Input Constraint:  CarLength > 0
#Constrains:  RollingStockCars, ProductTypes
CREATE TABLE RollingStockTypes (
    CarTypeName VARCHAR(255) NOT NULL PRIMARY KEY,
    CarLength INT NOT NULL
);

#RollingStockTypes
#Trigger to ensure that CarLength > 0.
DELIMITER $$
CREATE TRIGGER RollingStockTypesTrigger BEFORE INSERT ON RollingStockTypes
FOR EACH ROW
BEGIN
    IF NEW.CarLength <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'CarLength must be greater than 0.';
    END IF;
END$$
DELIMITER ;

#RollingStockCars
#Represents a physical train car used by players in a game session.
#Notes:  None.
#Pre-conditions:  A valid RollingStockTypes entity must exist.
#Input Constraint:  N/A
#Constrains:  RollingStockAtYards, RollingStockAtIndustries, Waybills,
#	ConsistedCars
CREATE TABLE RollingStockCars (
    CarID VARCHAR(255) NOT NULL PRIMARY KEY,
    CarTypeName VARCHAR(255) NOT NULL,
    FOREIGN KEY (CarTypeName)
        REFERENCES RollingStockTypes (CarTypeName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#Yards
#Defines a collection of tracks used to store trains and rolling stock when not
#	actively being used by crew in a game session.
#Notes:  Yards are the typical origination point of empty rolling stock cars
#	and the eventual destination for empty rolling stock cars after shipments
#	have been completed.
#Pre-conditions:  A valid Modules entity and a MainLines entity must exist.
#Input Constraint:  N/A
#Constrains:  RollingStockAtYards, Waybills
CREATE TABLE Yards (
    YardName VARCHAR(255) NOT NULL PRIMARY KEY,
    ModuleName VARCHAR(255) NOT NULL,
    LineName VARCHAR(255) NOT NULL,
    FOREIGN KEY (ModuleName)
        REFERENCES Modules (ModuleName)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (LineName)
        REFERENCES MainLines (LineName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#RollingStockAtYards
#Declares the identies of rolling stock cars currently at a specific train
#	yard.
#Notes:  Rolling stock cars not consisted to a train or reported at an industry
#	must report at a yard.
#Pre-conditions:  A valid RollingStockCars entity and Yards entity must exist.
#Input Constraint:  N/A
#Constrains:  None.
CREATE TABLE RollingStockAtYards (
    CarID VARCHAR(255) NOT NULL PRIMARY KEY,
    YardName VARCHAR(255) NOT NULL,
    TimeArrived TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (CarID)
        REFERENCES RollingStockCars (CarID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (YardName)
        REFERENCES Yards (YardName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#Industries
#Defines a business, accessable by rail, producing or consuming goods, and
#	transports those goods via rolling stock cars.
#Notes:  None.
#Pre-conditions:  A valid Modules entity and a MainLines entity must exist.
#Input Constraints:  N/A
#Constrains:  IndustriesAvailable, IndustryActivities, IndustryProducts,
#	IndustrySidings, SidingAssignments, RollingStockAtIndustries, Shipments 
CREATE TABLE Industries (
    IndustryName VARCHAR(255) NOT NULL PRIMARY KEY,
    ModuleName VARCHAR(255) NOT NULL,
    LineName VARCHAR(255) NOT NULL,
    FOREIGN KEY (ModuleName)
        REFERENCES Modules (ModuleName)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (LineName)
        REFERENCES MainLines (LineName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#IndustriesAvailable
#Defines the availability of an existing industry to be used in creating new
#	shipping orders.
#Notes:  Industries have the ability to be disabled during a game session to
#	prevent new shipping orders from being created.
#Pre-conditions:  A valid Industries entity must exist.
#Input Constraint:  N/A
#Constrains:  None.
CREATE TABLE IndustriesAvailable (
    IndustryName VARCHAR(255) NOT NULL PRIMARY KEY,
    IsAvailable BOOL NOT NULL,
    FOREIGN KEY (IndustryName)
        REFERENCES Industries (IndustryName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#IndustryActivities
#Defines the overall frequency of an existing industry to be considered for new
#	shipping orders.
#Pre-conditions:  A valid Industries entity must exist.
#Input Constraint:  ActivityLevel = {1, 2, 3} where 1 is lowest and 3 is
#	highest.
#Constrains:  None.
CREATE TABLE IndustryActivities (
    IndustryName VARCHAR(255) NOT NULL PRIMARY KEY,
    ActivityLevel INT NOT NULL,
    FOREIGN KEY (IndustryName)
        REFERENCES Industries (IndustryName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#IndustryActivities
#Trigger to ensure that ActivityLevel is limited to values 1, 2, or 3.
DELIMITER $$ 
CREATE TRIGGER IndustryActivitiesTrigger BEFORE INSERT ON IndustryActivities
FOR EACH ROW
BEGIN
    IF (NEW.ActivityLevel <= 0 OR NEW.ActivityLevel > 3) THEN 
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Activity level must be set to 1, 2, or 3.';
    END IF;
END $$
DELIMITER ;

#ProductTypes
#Define a product type and which rolling stock car type it is carried by.
#Notes:  None.
#Pre-conditions:  A valid RollingStockTypes entity must exist.
#Input Constraint:  N/A
#Constrains:  IndustryProducts, SidingAssignments, Shipments
CREATE TABLE ProductTypes (
    ProductTypeName VARCHAR(255) NOT NULL PRIMARY KEY,
    CarTypeName VARCHAR(255) NOT NULL,
    FOREIGN KEY (CarTypeName)
        REFERENCES RollingStockTypes (CarTypeName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#IndustryProducts
#Defines which product types an industry produces or consumes.
#Notes:  An industry product entity must be created for each product type
#	served.  If this entity exists and IsProducer is FALSE, then the industry
#	is a consumer for that product type.
#Pre-conditions:  A valid Industries entity and a ProductTypes entity must
#	exist.
#Input Constraint:  N/A
#Constrains:  None.
CREATE TABLE IndustryProducts (
    IndustryName VARCHAR(255) NOT NULL,
    ProductTypeName VARCHAR(255) NOT NULL,
    IsProducer BOOL NOT NULL,
    PRIMARY KEY (IndustryName , ProductTypeName),
    FOREIGN KEY (IndustryName)
        REFERENCES Industries (IndustryName)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ProductTypeName)
        REFERENCES ProductTypes (ProductTypeName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#IndustrySidings
#Defines which track siding an industry uses for rolling stock cars and
#	available lengths.
#Notes:  An industry must have at least one track siding to be accessable.
#	AvailableLength is used to determine if industries should be considered for
#	new shipping orders.  If AvailableLength is less than the length of an
#	incoming rolling stock car, the siding is considered to be "full" and
#	should not be considered for new shipping orders.
#Pre-conditions:  A valid Industries entity must exist.
#Input Constraints:  SidingLength > 0, AvailableLength > 0,
#	AvailableLength <= SidingLength
#Constrains:  SidingsAvailableLength, SidingAssignments,
#	RollingStockAtIndustries, Shipments
CREATE TABLE IndustrySidings (
    IndustryName VARCHAR(255) NOT NULL,
    SidingNumber INT NOT NULL,
    SidingLength INT NOT NULL,
    AvailableLength INT NOT NULL,
    PRIMARY KEY (IndustryName , SidingNumber),
    FOREIGN KEY (IndustryName)
        REFERENCES Industries (IndustryName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#IndustrySidings
#Trigger to ensure SidingLength > 0, AvailableLength > 0, and
#	AvailableLength <= SidingLength
DELIMITER $$ 
CREATE TRIGGER IndustrySidingsTrigger BEFORE INSERT ON IndustrySidings
FOR EACH ROW
BEGIN
    IF (NEW.SidingLength <= 0) THEN 
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Siding length must be greater than 0.';
    ELSEIF (NEW.AvailableLength <= 0) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Avaliable length must be greater than 0.';
    ELSEIF (NEW.AvailableLength > NEW.SidingLength) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Value exceeds maximum siding length.';
    END IF;
END $$
DELIMITER ;

#SidingAssignments
#Defines preferences for specific product types going to only specific industry
#	sidings.
#Notes:  An industry siding will accept all product types for an industry by
#	default.  Siding assignments will restrict a siding to only authorized
#	product types.  Siding assignments should not be used unless at least two
#	industry sidings exist.
#Pre-conditions:  A valid Industries entity must exist more than one declared
#	IndustrySidings entities and at least one ProductTypes entity.
#Input Constraint:  The count for total industry sidings at an industry must be
#	at least 2.
#Constrains:  None.
CREATE TABLE SidingAssignments (
    IndustryName VARCHAR(255) NOT NULL,
    SidingNumber INT NOT NULL,
    ProductTypeName VARCHAR(255) NOT NULL,
    PRIMARY KEY (IndustryName , SidingNumber , ProductTypeName),
    FOREIGN KEY (IndustryName)
        REFERENCES Industries (IndustryName)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (IndustryName , SidingNumber)
        REFERENCES IndustrySidings (IndustryName , SidingNumber)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ProductTypeName)
        REFERENCES ProductTypes (ProductTypeName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#SidingAssignments
#Trigger to ensure the count for total industry sidings at an industry must be at
#	least 2 before a siding assignment can be applied.
DELIMITER $$
CREATE TRIGGER SidingAssignmentsTrigger BEFORE INSERT ON SidingAssignments
FOR EACH ROW
BEGIN
    SET @industry = NEW.IndustryName;
    SET @sidingCount = (SELECT COUNT(*) FROM IndustrySidings WHERE IndustryName = @industry GROUP BY IndustryName);
    IF (@sidingCount < 2) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'At least two sidings must exist at this industry before siding assingments can be applied.';
    END IF;
    #TODO:  Add protection to ensure not all sidings have assignments
END$$
DELIMITER ;

#RollingStockAtIndustries
#Declares the identities of rolling stock cars current at a specific industry.
#Notes:  Rolling stock cars not consisted to a train or reported at a yard must
#	report at an industry.
#Pre-conditions:  A valid RollingStockCars entity and Industries entity must
#	exist.
#Input Constraint:  N/A
#Constrains:  None.
CREATE TABLE RollingStockAtIndustries (
    CarID VARCHAR(255) NOT NULL PRIMARY KEY,
    IndustryName VARCHAR(255) NOT NULL,
    SidingNumber INT NOT NULL,
    TimeArrived TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (CarID)
        REFERENCES RollingStockCars (CarID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (IndustryName)
        REFERENCES Industries (IndustryName)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (IndustryName , SidingNumber)
        REFERENCES IndustrySidings (IndustryName , SidingNumber)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#Trains
#Represents a physical locomotive (or locomotive group) for a player to control
#	in a game session.
#Notes:  TimeCreated is for reference only and should not be updated.
#Pre-conditions:  A Modules entity must exist for player origination.
#Input Constraint:  N/A
#Constrains:  TrainLocations, ConsistedCars, TrainCrews
CREATE TABLE Trains (
    TrainNumber INT NOT NULL PRIMARY KEY,
    LeadPower VARCHAR(255),
    DCCAddress CHAR(4),
    TimeCreated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

#TrainLocations
#Represents the location of a train on a layout.
#Notes:  TimeUpdated will apply the current timestamp automatically with any
#	activity.
#Pre-conditions:  A valid Trains entity and Modules entity must exist.
#Input Constraint:  N/A
#Constrains:  None.
CREATE TABLE TrainLocations (
    TrainNumber INT NOT NULL PRIMARY KEY,
    ModuleName VARCHAR(255) NOT NULL,
    TimeUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (TrainNumber)
        REFERENCES Trains (TrainNumber)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ModuleName)
        REFERENCES Modules (ModuleName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#Shipments
#Declares a shipping order of a product type for pickup at one industry and
#	delivery to another industry.
#Notes:  Shipping orders are created on demand when rolling stock cars are
#	added to a game session (version 2.0).
#Pre-conditions:  A valid ProductTypes entity and two Industries entities must
#	exist.  For each industry, one IndustrySidings entity must exist.
#Input Constraint:  FromIndustry <> ToIndustry
#Constrains:  Waybills, ShipmentsLoaded, ShipmentsUnloaded
CREATE TABLE Shipments (
    ShipmentID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    ProductTypeName VARCHAR(255) NOT NULL,
    FromIndustry VARCHAR(255) NOT NULL,
    FromSiding INT NOT NULL,
    ToIndustry VARCHAR(255) NOT NULL,
    ToSiding INT NOT NULL,
    TimeCreated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductTypeName)
        REFERENCES ProductTypes (ProductTypeName)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (FromIndustry)
        REFERENCES Industries (IndustryName)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (FromIndustry , FromSiding)
        REFERENCES IndustrySidings (IndustryName , SidingNumber)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ToIndustry)
        REFERENCES Industries (IndustryName)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ToIndustry , ToSiding)
        REFERENCES IndustrySidings (IndustryName , SidingNumber)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#Shipments
#Trigger to ensure that FromIndustry and ToIndustry are not the same entities.
DELIMITER $$
CREATE TRIGGER ShipmentsTrigger BEFORE INSERT ON Shipments
FOR EACH ROW
BEGIN
    IF (NEW.FromIndustry = NEW.ToIndustry) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A shipment can only be created to service two different industries.';
    END IF;
END$$
DELIMITER ;

#Waybills
#Declares the association of a shipping order and a specific rolling stock car.
#Notes:  ReturnToYard determines the location empty rolling stock will be sent
#	to after the shipping order is complete.
#Pre-conditions:  At least one valid entity for RollingStockCars, Shipments,
#	and Yards must exist.
#Input Constraint:  N/A
#Constrains:  None.
CREATE TABLE Waybills (
    CarID VARCHAR(255) NOT NULL PRIMARY KEY,
    ShipmentID INT NOT NULL,
    YardName VARCHAR(255) NOT NULL,
    FOREIGN KEY (CarID)
        REFERENCES RollingStockCars (CarID)
        ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (ShipmentID)
        REFERENCES Shipments (ShipmentID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (YardName)
        REFERENCES Yards (YardName)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#ShipmentsLoaded
#Declares if a shipping order has been picked up from an Industry producing a
#	certain product type.
#Note:  If this entity exists, the product has been loaded onto a rolling stock
#	car.
#Pre-conditions:  A valid Shipments entity must exist.
#Input Constraint:  N/A
#Constrains:  None.
CREATE TABLE ShipmentsLoaded (
    ShipmentID INT NOT NULL PRIMARY KEY,
    TimeLoaded TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ShipmentID)
        REFERENCES Shipments (ShipmentID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#ShipmentsUnloaded
#Declares if a shipping order has been delivered to an Industry consuming a
#	certain product type.
#Note:  If this entity exists, the product has been unloaded from a rolling
#	stock car.
#Pre-conditions:  A valid Shipments entity must exist.
#Input Constraint:  N/A
#Constrains:  None.
CREATE TABLE ShipmentsUnloaded (
    ShipmentID INT NOT NULL PRIMARY KEY,
    TimeUnloaded TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ShipmentID)
        REFERENCES Shipments (ShipmentID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

#ConsistedCars
#Represents the association of individual rolling stock cars attached to
#	trains.
#Notes:  None.
#Pre-conditions:  A valid Trains entity must exist, and for each car added, a
#	RollingStockCars entity must exist.
#Input Constraint:  N/A
#Constrains:  None.
CREATE TABLE ConsistedCars (
    TrainNumber INT NOT NULL,
    CarID VARCHAR(255) NOT NULL UNIQUE,
    TimeAdded TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (TrainNumber , CarID),
    FOREIGN KEY (TrainNumber)
        REFERENCES Trains (TrainNumber)
        ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (CarID)
        REFERENCES RollingStockCars (CarID)
        ON DELETE NO ACTION ON UPDATE NO ACTION
);

#TrainCrews
#Represents a player identity in a game session and declares the association of
#	a crew with a train.
#Notes:  None.
#Pre-conditions:  A valid Trains entity must exist.
#Input Constraint:  N/A
#Constrains:  None.
CREATE TABLE TrainCrews (
    TrainNumber INT NOT NULL PRIMARY KEY,
    CrewName VARCHAR(255) NOT NULL UNIQUE,
    TimeJoined TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (TrainNumber)
        REFERENCES Trains (TrainNumber)
        ON DELETE NO ACTION ON UPDATE NO ACTION
);