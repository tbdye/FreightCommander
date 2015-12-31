#This test data creates a small model railroad layout, train cars, and players.
#	Data insertion is handled in a sequence order that is either required by
#	the database or encountered through normal program interaction.  This data,
#	as it is, will only be used for development testing.  Normal game operation
#	allows for the application or interface to supply data.

#Section A:  Initalize Game Parameters
#
#Expected Insertion Order:
#Define all RollingStockTypes.
#Define all ProductTypes.

#Define rolling stock car types
#Notes:  For each category of rolling stock in use, declare a car type and car
#	length.
INSERT INTO RollingStockTypes VALUES ('Box Car', 65);
INSERT INTO RollingStockTypes VALUES ('Centerbeam Flat', 85);
INSERT INTO RollingStockTypes VALUES ('Flat Car', 65);
INSERT INTO RollingStockTypes VALUES ('Gondola', 65);
INSERT INTO RollingStockTypes VALUES ('Long Hopper', 75);
INSERT INTO RollingStockTypes VALUES ('Short Hopper', 55);
INSERT INTO RollingStockTypes VALUES ('Open Hopper', 75);
INSERT INTO RollingStockTypes VALUES ('Ore Car', 40);
INSERT INTO RollingStockTypes VALUES ('Reefer', 65);
INSERT INTO RollingStockTypes VALUES ('Stock Car', 55);
INSERT INTO RollingStockTypes VALUES ('Tank Car', 65);
INSERT INTO RollingStockTypes VALUES ('Wood Chip Car', 75);

#Define product type assignments
#Notes:  For each category of rolling stock car type, multiple product types
#	can be carried.  Declare all product types and rolling stock car
#	associations.
INSERT INTO ProductTypes VALUES ('Crates', 'Box Car');
INSERT INTO ProductTypes VALUES ('Metal', 'Box Car');
INSERT INTO ProductTypes VALUES ('Paper', 'Box Car');
INSERT INTO ProductTypes VALUES ('Tools', 'Box Car');
INSERT INTO ProductTypes VALUES ('General Merchandise', 'Box Car');
INSERT INTO ProductTypes VALUES ('Lumber', 'Centerbeam Flat');
INSERT INTO ProductTypes VALUES ('Bulk Equipment', 'Flat Car');
INSERT INTO ProductTypes VALUES ('Logs', 'Flat Car');
INSERT INTO ProductTypes VALUES ('Aggregate', 'Gondola');
INSERT INTO ProductTypes VALUES ('Scrap Metal', 'Gondola');
INSERT INTO ProductTypes VALUES ('Feed', 'Long Hopper');
INSERT INTO ProductTypes VALUES ('Fertilizer', 'Long Hopper');
INSERT INTO ProductTypes VALUES ('Grain', 'Long Hopper');
INSERT INTO ProductTypes VALUES ('Coal', 'Open Hopper');
INSERT INTO ProductTypes VALUES ('Gravel', 'Open Hopper');
INSERT INTO ProductTypes VALUES ('Iron', 'Ore Car');
INSERT INTO ProductTypes VALUES ('Dairy', 'Reefer');
INSERT INTO ProductTypes VALUES ('Manufactured Foods', 'Reefer');
INSERT INTO ProductTypes VALUES ('Meats', 'Reefer');
INSERT INTO ProductTypes VALUES ('Produce', 'Reefer');
INSERT INTO ProductTypes VALUES ('Concrete', 'Short Hopper');
INSERT INTO ProductTypes VALUES ('Plastics', 'Short Hopper');
INSERT INTO ProductTypes VALUES ('Livestock', 'Stock Car');
INSERT INTO ProductTypes VALUES ('Chemicals', 'Tank Car');
INSERT INTO ProductTypes VALUES ('Fuels', 'Tank Car');
INSERT INTO ProductTypes VALUES ('Gasses', 'Tank Car');
INSERT INTO ProductTypes VALUES ('Garbage', 'Wood Chip Car');
INSERT INTO ProductTypes VALUES ('Wood Chips', 'Wood Chip Car');

#Section B:  Build Layout
#Notes:  Data declared in this section is likely to remain persistent and will
#	be used across multiple game sessions.
#
#Expected Insertion Order (for each Module):
#Declare Modules
#Declare MainLines for Modules
#Declare Junctions on MainLines
#Declare Yards on MainLines
#Declare Industries on MainLines
#Declare IndustriesAvailable for Industries
#Declare IndustryActivities for Industries
#Declare IndustryProducts for Industries
#Declare IndustrySidings for Industries
#Declare SidingsAvailableLength for IndustrySidings
#Declare SidingAssignments for IndustrySidings

#Populate the Black River Yard module.
INSERT INTO Modules VALUES ('Black River Yard', 'Mike Donnelly', 'oNeTrak', '3-Straight', 'Contains the Black River Yard');
INSERT INTO MainLines VALUES ('Red', 'Black River Yard', TRUE);
INSERT INTO MainLines VALUES ('Green', 'Black River Yard', FALSE);
INSERT INTO Junctions VALUES (DEFAULT, 'Black River Yard', 'Red', 'Green');
INSERT INTO Yards VALUE ('Black River Yard', 'Black River Yard', 'Red');
INSERT INTO Industries VALUES ('MMI Transfer Site 3', 'Black River Yard', 'Green');
INSERT INTO Industries VALUES ('E.E. Aldrin Sawmill', 'Black River Yard', 'Green');
INSERT INTO Industries VALUES ('B.R. Engine House', 'Black River Yard', 'Green');
INSERT INTO Industries VALUES ('Black River MOW Shop', 'Black River Yard', 'Green');
INSERT INTO IndustriesAvailable VALUES ('MMI Transfer Site 3', TRUE);
INSERT INTO IndustriesAvailable VALUES ('E.E. Aldrin Sawmill', TRUE);
INSERT INTO IndustriesAvailable VALUES ('B.R. Engine House', TRUE);
INSERT INTO IndustriesAvailable VALUES ('Black River MOW Shop', TRUE);
INSERT INTO IndustryActivities VALUES ('MMI Transfer Site 3', 2);
INSERT INTO IndustryActivities VALUES ('E.E. Aldrin Sawmill', 2);
INSERT INTO IndustryActivities VALUES ('B.R. Engine House', 1);
INSERT INTO IndustryActivities VALUES ('Black River MOW Shop', 1);
INSERT INTO IndustryProducts VALUES ('B.R. Engine House', 'Scrap Metal', TRUE);
INSERT INTO IndustryProducts VALUES ('B.R. Engine House', 'Metal', FALSE);
INSERT INTO IndustryProducts VALUES ('B.R. Engine House', 'Bulk Equipment', FALSE);
INSERT INTO IndustryProducts VALUES ('Black River MOW Shop', 'Scrap Metal', TRUE);
INSERT INTO IndustryProducts VALUES ('Black River MOW Shop', 'Garbage', TRUE);
INSERT INTO IndustryProducts VALUES ('Black River MOW Shop', 'Bulk Equipment', FALSE);
INSERT INTO IndustryProducts VALUES ('MMI Transfer Site 3', 'General Merchandise', FALSE);
INSERT INTO IndustryProducts VALUES ('MMI Transfer Site 3', 'Dairy', FALSE);
INSERT INTO IndustryProducts VALUES ('MMI Transfer Site 3', 'Manufactured Foods', FALSE);
INSERT INTO IndustryProducts VALUES ('MMI Transfer Site 3', 'Meats', FALSE);
INSERT INTO IndustryProducts VALUES ('MMI Transfer Site 3', 'Produce', FALSE);
INSERT INTO IndustryProducts VALUES ('E.E. Aldrin Sawmill', 'Lumber', TRUE);
INSERT INTO IndustryProducts VALUES ('E.E. Aldrin Sawmill', 'Wood Chips', TRUE);
INSERT INTO IndustryProducts VALUES ('E.E. Aldrin Sawmill', 'Bulk Equipment', FALSE);
INSERT INTO IndustryProducts VALUES ('E.E. Aldrin Sawmill', 'Logs', FALSE);
INSERT INTO IndustrySidings VALUES ('B.R. Engine House', 1, 90, 90);
INSERT INTO IndustrySidings VALUES ('B.R. Engine House', 3, 200, 200);
INSERT INTO IndustrySidings VALUES ('MMI Transfer Site 3', 1, 100, 100);
INSERT INTO IndustrySidings VALUES ('MMI Transfer Site 3', 2, 100, 100);
INSERT INTO IndustrySidings VALUES ('MMI Transfer Site 3', 3, 150, 150);
INSERT INTO IndustrySidings VALUES ('E.E. Aldrin Sawmill', 1, 300, 300);
INSERT INTO SidingAssignments VALUES ('B.R. Engine House', 1, 'Scrap Metal');
INSERT INTO SidingAssignments VALUES ('MMI Transfer Site 3', 3, 'General Merchandise');
INSERT INTO SidingAssignments VALUES ('MMI Transfer Site 3', 3, 'Manufactured Foods');

#Populate the Crossover module.
INSERT INTO Modules VALUES ('Crossover', 'Al Lowe', 'Ntrak', 'Straight', 'Access to all main lines available');
INSERT INTO MainLines VALUES ('Red', 'Crossover', TRUE);
INSERT INTO MainLines VALUES ('Yellow', 'Crossover', TRUE);
INSERT INTO MainLines VALUES ('Blue', 'Crossover', TRUE);
INSERT INTO Junctions VALUES (DEFAULT, 'Crossover', 'Red', 'Yellow');
INSERT INTO Junctions VALUES (DEFAULT, 'Crossover', 'Yellow', 'Blue');

#Populate the 180 Farms module.
INSERT INTO Modules VALUES ('180 Farms', 'Al Lowe', 'oNeTrak', '180 Corner', NULL);
INSERT INTO MainLines VALUES ('Red', '180 Farms', TRUE);
INSERT INTO Industries VALUES ('Half Circle Farms', '180 Farms', 'Red');
INSERT INTO IndustriesAvailable VALUES ('Half Circle Farms', TRUE);
INSERT INTO IndustryActivities VALUES ('Half Circle Farms', 2);
INSERT INTO IndustryProducts VALUES ('Half Circle Farms', 'Fertilizer', TRUE);
INSERT INTO IndustryProducts VALUES ('Half Circle Farms', 'Dairy', TRUE);
INSERT INTO IndustryProducts VALUES ('Half Circle Farms', 'Produce', TRUE);
INSERT INTO IndustryProducts VALUES ('Half Circle Farms', 'Livestock', TRUE);
INSERT INTO IndustryProducts VALUES ('Half Circle Farms', 'Garbage', TRUE);
INSERT INTO IndustryProducts VALUES ('Half Circle Farms', 'Lumber', FALSE);
INSERT INTO IndustryProducts VALUES ('Half Circle Farms', 'Bulk Equipment', FALSE);
INSERT INTO IndustryProducts VALUES ('Half Circle Farms', 'Feed', FALSE);
INSERT INTO IndustryProducts VALUES ('Half Circle Farms', 'Grain', FALSE);
INSERT INTO IndustryProducts VALUES ('Half Circle Farms', 'Fuels', FALSE);
INSERT INTO IndustryProducts VALUES ('Half Circle Farms', 'Gasses', FALSE);
INSERT INTO IndustrySidings VALUES ('Half Circle Farms', 1, 600, 600);

#Populate the Grain Elevator module.
INSERT INTO Modules VALUES ('Grain Elevator', 'Al Lowe', 'oNeTrak', 'Straight', NULL);
INSERT INTO MainLines VALUES ('Red', 'Grain Elevator', TRUE);
INSERT INTO Industries VALUES ('Oatus Elevator', 'Grain Elevator', 'Red');
INSERT INTO IndustriesAvailable VALUES ('Oatus Elevator', TRUE);
INSERT INTO IndustryActivities VALUES ('Oatus Elevator', 2);
INSERT INTO IndustryProducts VALUES ('Oatus Elevator', 'Feed', TRUE);
INSERT INTO IndustryProducts VALUES ('Oatus Elevator', 'Grain', TRUE);
INSERT INTO IndustrySidings VALUES ('Oatus Elevator', 1, 200, 200);

#Populate the Palin Bridge module.
INSERT INTO Modules VALUES ('Palin Bridge', 'Al Lowe', 'oNeTrak', 'Straight', NULL);
INSERT INTO MainLines VALUES ('Red', 'Palin Bridge', TRUE);
INSERT INTO Industries VALUES ('Palin Interchange', 'Palin Bridge', 'Red');
INSERT INTO IndustriesAvailable VALUES ('Palin Interchange', TRUE);
INSERT INTO IndustryActivities VALUES ('Palin Interchange', 1);
INSERT INTO IndustryProducts VALUES ('Palin Interchange', 'Feed', FALSE);
INSERT INTO IndustryProducts VALUES ('Palin Interchange', 'Fertilizer', FALSE);
INSERT INTO IndustryProducts VALUES ('Palin Interchange', 'Grain', FALSE);
INSERT INTO IndustryProducts VALUES ('Palin Interchange', 'Coal', FALSE);
INSERT INTO IndustryProducts VALUES ('Palin Interchange', 'Gravel', FALSE);
INSERT INTO IndustryProducts VALUES ('Palin Interchange', 'Concrete', FALSE);
INSERT INTO IndustryProducts VALUES ('Palin Interchange', 'Livestock', FALSE);
INSERT INTO IndustryProducts VALUES ('Palin Interchange', 'Fuels', FALSE);
INSERT INTO IndustryProducts VALUES ('Palin Interchange', 'Gasses', FALSE);
INSERT INTO IndustrySidings VALUES ('Palin Interchange', 1, 500, 500);

#Populate the Bauxen Crate module.
INSERT INTO Modules VALUES ('Bauxen Crate', 'Al Lowe', 'Transition', 'Straight', 'Access to all lines available');
INSERT INTO MainLines VALUES ('Red', 'Bauxen Crate', TRUE);
INSERT INTO MainLines VALUES ('Alternate Blue', 'Bauxen Crate', FALSE);
INSERT INTO MainLines VALUES ('Yellow', 'Bauxen Crate', FALSE);
INSERT INTO MainLines VALUES ('Blue', 'Bauxen Crate', FALSE);
INSERT INTO Junctions VALUES (DEFAULT, 'Bauxen Crate', 'Red', 'Alternate Blue');
INSERT INTO Junctions VALUES (DEFAULT, 'Bauxen Crate', 'Red', 'Blue');
INSERT INTO Junctions VALUES (DEFAULT, 'Bauxen Crate', 'Red', 'Yellow');
INSERT INTO Industries VALUES ('Bauxen Crates', 'Bauxen Crate', 'Red');
INSERT INTO IndustriesAvailable VALUES ('Bauxen Crates', TRUE);
INSERT INTO IndustryActivities VALUES ('Bauxen Crates', 3);
INSERT INTO IndustryProducts VALUES ('Bauxen Crates', 'Crates', TRUE);
INSERT INTO IndustryProducts VALUES ('Bauxen Crates', 'Wood Chips', TRUE);
INSERT INTO IndustryProducts VALUES ('Bauxen Crates', 'Metal', FALSE);
INSERT INTO IndustryProducts VALUES ('Bauxen Crates', 'Lumber', FALSE);
INSERT INTO IndustrySidings VALUES ('Bauxen Crates', 3, 150, 150);
INSERT INTO IndustrySidings VALUES ('Bauxen Crates', 4, 150, 150);

#Populate the Scott Corner module.
INSERT INTO Modules VALUES ('Scott Corner', 'Al Lowe', 'Ntrak', 'Corner', NULL);
INSERT INTO MainLines VALUES ('Red', 'Scott Corner', TRUE);
INSERT INTO MainLines VALUES ('Yellow', 'Scott Corner', TRUE);
INSERT INTO MainLines VALUES ('Blue', 'Scott Corner', TRUE);

#Populate the Trainyard Mall module.
INSERT INTO Modules VALUES ('Trainyard Mall', 'Al Lowe', 'Ntrak', 'Corner', NULL);
INSERT INTO MainLines VALUES ('Red', 'Trainyard Mall', TRUE);
INSERT INTO MainLines VALUES ('Yellow', 'Trainyard Mall', TRUE);
INSERT INTO MainLines VALUES ('Blue', 'Trainyard Mall', TRUE);

#Populate the Chesterfield module.
INSERT INTO Modules VALUES ('Chesterfield', 'Al Lowe', 'Ntrak', '2-Straight', 'No crossovers');
INSERT INTO MainLines VALUES ('Red', 'Chesterfield', TRUE);
INSERT INTO MainLines VALUES ('Yellow', 'Chesterfield', TRUE);
INSERT INTO MainLines VALUES ('Blue', 'Chesterfield', TRUE);
INSERT INTO MainLines VALUES ('Alternate Blue', 'Chesterfield', TRUE);
INSERT INTO Junctions VALUES (DEFAULT, 'Chesterfield', 'Blue', 'Alternate Blue');
INSERT INTO Industries VALUES ('Chesterfield Power Plant', 'Chesterfield', 'Red');
INSERT INTO Industries VALUES ('Cobra Golf', 'Chesterfield', 'Blue');
INSERT INTO Industries VALUES ('Kesselring Machine Shop', 'Chesterfield', 'Yellow');
INSERT INTO Industries VALUES ('Max Distributing', 'Chesterfield', 'Yellow');
INSERT INTO Industries VALUES ('Lostry Mine', 'Chesterfield', 'Blue');
INSERT INTO Industries VALUES ('Puget Warehouse', 'Chesterfield', 'Blue');
INSERT INTO Industries VALUES ('Tuggle Manufacturing', 'Chesterfield', 'Yellow');
INSERT INTO Industries VALUES ('Wonder Model Trains', 'Chesterfield', 'Red');
INSERT INTO IndustriesAvailable VALUES ('Chesterfield Power Plant', TRUE);
INSERT INTO IndustriesAvailable VALUES ('Cobra Golf', TRUE);
INSERT INTO IndustriesAvailable VALUES ('Kesselring Machine Shop', TRUE);
INSERT INTO IndustriesAvailable VALUES ('Max Distributing', TRUE);
INSERT INTO IndustriesAvailable VALUES ('Lostry Mine', TRUE);
INSERT INTO IndustriesAvailable VALUES ('Puget Warehouse', TRUE);
INSERT INTO IndustriesAvailable VALUES ('Tuggle Manufacturing', TRUE);
INSERT INTO IndustriesAvailable VALUES ('Wonder Model Trains', TRUE);
INSERT INTO IndustryActivities VALUES ('Chesterfield Power Plant', 3);
INSERT INTO IndustryActivities VALUES ('Cobra Golf', 2);
INSERT INTO IndustryActivities VALUES ('Kesselring Machine Shop', 1);
INSERT INTO IndustryActivities VALUES ('Max Distributing', 2);
INSERT INTO IndustryActivities VALUES ('Lostry Mine', 3);
INSERT INTO IndustryActivities VALUES ('Puget Warehouse', 3);
INSERT INTO IndustryActivities VALUES ('Tuggle Manufacturing', 2);
INSERT INTO IndustryActivities VALUES ('Wonder Model Trains', 1);
INSERT INTO IndustryProducts VALUES ('Chesterfield Power Plant', 'Bulk Equipment', FALSE);
INSERT INTO IndustryProducts VALUES ('Chesterfield Power Plant', 'Coal', FALSE);
INSERT INTO IndustryProducts VALUES ('Cobra Golf', 'Scrap Metal', TRUE);
INSERT INTO IndustryProducts VALUES ('Cobra Golf', 'Crates', FALSE);
INSERT INTO IndustryProducts VALUES ('Cobra Golf', 'Metal', FALSE);
INSERT INTO IndustryProducts VALUES ('Cobra Golf', 'Plastics', FALSE);
INSERT INTO IndustryProducts VALUES ('Kesselring Machine Shop', 'Bulk Equipment', TRUE);
INSERT INTO IndustryProducts VALUES ('Kesselring Machine Shop', 'Scrap Metal', TRUE);
INSERT INTO IndustryProducts VALUES ('Kesselring Machine Shop', 'Crates', FALSE);
INSERT INTO IndustryProducts VALUES ('Kesselring Machine Shop', 'Metal', FALSE);
INSERT INTO IndustryProducts VALUES ('Max Distributing', 'Garbage', TRUE);
INSERT INTO IndustryProducts VALUES ('Max Distributing', 'Crates', FALSE);
INSERT INTO IndustryProducts VALUES ('Max Distributing', 'Paper', FALSE);
INSERT INTO IndustryProducts VALUES ('Max Distributing', 'Tools', FALSE);
INSERT INTO IndustryProducts VALUES ('Lostry Mine', 'Aggregate', TRUE);
INSERT INTO IndustryProducts VALUES ('Lostry Mine', 'Coal', TRUE);
INSERT INTO IndustryProducts VALUES ('Lostry Mine', 'Iron', TRUE);
INSERT INTO IndustryProducts VALUES ('Lostry Mine', 'Tools', FALSE);
INSERT INTO IndustryProducts VALUES ('Lostry Mine', 'Lumber', FALSE);
INSERT INTO IndustryProducts VALUES ('Lostry Mine', 'Bulk Equipment', FALSE);
INSERT INTO IndustryProducts VALUES ('Puget Warehouse', 'General Merchandise', TRUE);
INSERT INTO IndustryProducts VALUES ('Puget Warehouse', 'Garbage', TRUE);
INSERT INTO IndustryProducts VALUES ('Tuggle Manufacturing', 'Scrap Metal', TRUE);
INSERT INTO IndustryProducts VALUES ('Tuggle Manufacturing', 'Garbage', TRUE);
INSERT INTO IndustryProducts VALUES ('Tuggle Manufacturing', 'Crates', FALSE);
INSERT INTO IndustryProducts VALUES ('Tuggle Manufacturing', 'Metal', FALSE);
INSERT INTO IndustryProducts VALUES ('Tuggle Manufacturing', 'Paper', FALSE);
INSERT INTO IndustryProducts VALUES ('Tuggle Manufacturing', 'Tools', FALSE);
INSERT INTO IndustryProducts VALUES ('Tuggle Manufacturing', 'Lumber', FALSE);
INSERT INTO IndustryProducts VALUES ('Tuggle Manufacturing', 'Plastics', FALSE);
INSERT INTO IndustryProducts VALUES ('Tuggle Manufacturing', 'Chemicals', FALSE);
INSERT INTO IndustryProducts VALUES ('Wonder Model Trains', 'Garbage', TRUE);
INSERT INTO IndustryProducts VALUES ('Wonder Model Trains', 'Metal', FALSE);
INSERT INTO IndustryProducts VALUES ('Wonder Model Trains', 'Paper', FALSE);
INSERT INTO IndustryProducts VALUES ('Wonder Model Trains', 'Plastics', FALSE);
INSERT INTO IndustrySidings VALUES ('Chesterfield Power Plant', 1, 160, 160);
INSERT INTO IndustrySidings VALUES ('Wonder Model Trains', 1, 160, 160);
INSERT INTO IndustrySidings VALUES ('Max Distributing', 1, 200, 200);
INSERT INTO IndustrySidings VALUES ('Tuggle Manufacturing', 1, 200, 200);
INSERT INTO IndustrySidings VALUES ('Kesselring Machine Shop', 1, 200, 200);
INSERT INTO IndustrySidings VALUES ('Puget Warehouse', 1, 200, 200);
INSERT INTO IndustrySidings VALUES ('Cobra Golf', 1, 160, 160);
INSERT INTO IndustrySidings VALUES ('Lostry Mine', 1, 160, 160);

#Populate the Pure Oil module.
INSERT INTO Modules VALUES ('Pure Oil', 'Al Lowe', 'Transition', 'Straight', 'Access to all main lines available.');
INSERT INTO MainLines VALUES ('Red', 'Pure Oil', TRUE);
INSERT INTO MainLines VALUES ('Alternate Blue', 'Pure Oil', FALSE);
INSERT INTO MainLines VALUES ('Yellow', 'Pure Oil', FALSE);
INSERT INTO MainLines VALUES ('Blue', 'Pure Oil', FALSE);
INSERT INTO Junctions VALUES (DEFAULT, 'Pure Oil', 'Red', 'Alternate Blue');
INSERT INTO Junctions VALUES (DEFAULT, 'Pure Oil', 'Red', 'Blue');
INSERT INTO Junctions VALUES (DEFAULT, 'Pure Oil', 'Red', 'Yellow');
INSERT INTO Industries VALUES ('Sunset Feed', 'Pure Oil', 'Red');
INSERT INTO Industries VALUES ('Pure Oil', 'Pure Oil', 'Red');
INSERT INTO Industries VALUES ('LGP Professionals', 'Pure Oil', 'Red');
INSERT INTO IndustriesAvailable VALUES ('Sunset Feed', TRUE);
INSERT INTO IndustriesAvailable VALUES ('Pure Oil', TRUE);
INSERT INTO IndustriesAvailable VALUES ('LGP Professionals', TRUE);
INSERT INTO IndustryActivities VALUES ('Sunset Feed', 3);
INSERT INTO IndustryActivities VALUES ('Pure Oil', 2);
INSERT INTO IndustryActivities VALUES ('LGP Professionals', 1);
INSERT INTO IndustryProducts VALUES ('Pure Oil', 'Fuels', TRUE);
INSERT INTO IndustryProducts VALUES ('Sunset Feed', 'Feed', TRUE);
INSERT INTO IndustryProducts VALUES ('Sunset Feed', 'Garbage', TRUE);
INSERT INTO IndustryProducts VALUES ('Sunset Feed', 'Grain', FALSE);
INSERT INTO IndustryProducts VALUES ('Sunset Feed', 'Dairy', FALSE);
INSERT INTO IndustryProducts VALUES ('Sunset Feed', 'Meats', FALSE);
INSERT INTO IndustryProducts VALUES ('Sunset Feed', 'Produce', FALSE);
INSERT INTO IndustryProducts VALUES ('LGP Professionals', 'Gasses', TRUE);
INSERT INTO IndustrySidings VALUES ('Pure Oil', 3, 100, 100);
INSERT INTO IndustrySidings VALUES ('Pure Oil', 4, 100, 100);
INSERT INTO IndustrySidings VALUES ('Sunset Feed', 4, 200, 200);
INSERT INTO IndustrySidings VALUES ('LGP Professionals', 4, 120, 120);

#Section C:  Initialize Game Session
#Notes:  This section contains non-persistent data which typically only exists
#	for a single game session.  A game session is considered active when
#	trains, rolling stock cars, and crews are in existence.  To start a game,
#	select which modules are present from the library of previously defined
#	modules and declare which region they are to be in to determine layout
#	shape.
#
#Expected Insertion Order:
#Declare all ModulesAvailable for Modules.
#Declare all Regions for Modules.

#Activate available modules for gameplay.
INSERT INTO ModulesAvailable VALUES ('Black River Yard', TRUE);
INSERT INTO ModulesAvailable VALUES ('Crossover', TRUE);
INSERT INTO ModulesAvailable VALUES ('180 Farms', TRUE);
INSERT INTO ModulesAvailable VALUES ('Grain Elevator', TRUE);
INSERT INTO ModulesAvailable VALUES ('Palin Bridge', TRUE);
INSERT INTO ModulesAvailable VALUES ('Bauxen Crate', TRUE);
INSERT INTO ModulesAvailable VALUES ('Scott Corner', TRUE);
INSERT INTO ModulesAvailable VALUES ('Trainyard Mall', TRUE);
INSERT INTO ModulesAvailable VALUES ('Chesterfield', TRUE);
INSERT INTO ModulesAvailable VALUES ('Pure Oil', TRUE);

#Add modules into specific regions on the map.
INSERT INTO Regions VALUES ('South', 'Black River Yard');
INSERT INTO Regions VALUES ('South', 'Crossover');
INSERT INTO Regions VALUES ('West', '180 Farms');
INSERT INTO Regions VALUES ('West', 'Grain Elevator');
INSERT INTO Regions VALUES ('East', 'Palin Bridge');
INSERT INTO Regions VALUES ('East', 'Bauxen Crate');
INSERT INTO Regions VALUES ('East', 'Scott Corner');
INSERT INTO Regions VALUES ('North', 'Trainyard Mall');
INSERT INTO Regions VALUES ('North', 'Chesterfield');
INSERT INTO Regions VALUES ('North', 'Pure Oil');