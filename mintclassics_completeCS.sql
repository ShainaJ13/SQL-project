#Project Objectives
#1. Explore products currently in inventory.
#2. Determine important factors that may influence inventory reorganization/reduction.
#3. Provide analytic insights and data-driven recommendations.

#For disabling all group by which causes issue in perfomring group by fuction
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
#--------------------------------------------------------------------------------------------------------------
#PRODUCTS TABLE
#Product line and quantity (TOTAL STOCK)
SELECT productLine, SUM(DISTINCT quantityInStock) AS totalStock,
COUNT(DISTINCT productName) AS totalVariants
FROM products
GROUP BY productLine;

#Product line, quantity (TOTAL STOCK) and their respective warehouse code with total variants (for warehouse a, motorcycles is also included
# and for warehouse d ships and trains are also included)
SELECT warehouseCode, productLine, SUM(DISTINCT quantityInStock) AS totalStock,
COUNT(DISTINCT productName) AS totalVariants
FROM products
GROUP BY warehouseCode;

SELECT SUM(quantityInStock)
FROM products;
#TOTAL STOCK = 5,55,131
#JOINING TABLES----------------------------------------------------------------------------------------
#For order and orderdetail- join them on orderNumber 
CREATE TABLE orderdetails_full
SELECT orders.orderNumber, orders.orderDate, orders.status, orders.comments, orders.customerNumber,
orderdetails.productCode, orderdetails.quantityOrdered, orderdetails.priceEach
FROM orders
INNER JOIN orderdetails ON orders.orderNumber = orderdetails.orderNumber;

SELECT SUM(quantityOrdered)
FROM mintclassics.orderdetails_full;
# TOTAL ORDERS QUANTITY 1,05,516

SELECT SUM(quantityOrdered * priceEach) AS totalSale
FROM mintclassics.orderdetails_full;
#total sale- 96,04,190.61

 
 #joining product and orderdetails_full for further calculation-------------
 CREATE TABLE productsale
 SELECT orderdetails_full.*, products.productName, products.productLine, products.quantityInStock,
 products.buyPrice, products.MSRP, products.warehouseCode
 FROM orderdetails_full
 INNER JOIN products ON orderdetails_full.productCode = products.productCode;
#----------------------------------------------------------------------------------------------------------------

#PRODUCTSALE TABLE
#Total stock vs total orders for each product line and their respective warehouse code with total variants(FOR 'STOCK ORDERED')
SELECT warehouseCode, productLine, SUM(DISTINCT quantityInStock) AS totalStock, SUM(DISTINCT quantityOrdered) AS totalOrder,
COUNT(DISTINCT productName) AS totalVariants
FROM productsale
GROUP BY productLine
ORDER BY totalstock DESC;

#Quantity is stock top 5 and bottom 5 vs quantity ordered
SELECT productName, productLine, quantityInStock, SUM(quantityOrdered)
FROM productsale
GROUP BY productName
ORDER BY quantityInStock DESC;
#highest - 
#	2002 Suzuki XREO	Motorcycles		9997	1028
#	1995 Honda Civic	Classic Cars	9772	917
#	America West Airlines B757-200	Planes		9653	984
#	2002 Chevy Corvette	Classic Cars		9446      894
#	1932 Model A Ford J-Coupe	Vintage Cars	9354	957
#Lowest-
#	Pont Yacht	Ships		414	    958
#	1997 BMW F650 ST	Motorcycles		178	  1014
#	1928 Ford Phaeton Deluxe	Vintage Cars	136	  972
#	1968 Ford Mustang	Classic Cars	68	 933
#	1960 BSA Gold Star DBD34	Motorcycles 	15	  1015

# Profit per piece top 5 and bottom 5 
SELECT productName, productLine, quantityInStock, (MSRP - buyPrice) AS profitperpiece
FROM products
ORDER BY profitperpiece DESC;
#highest 
#	1952 Alpine Renault 1300	Classic Cars   7305 	115.72
#	2001 Ferrari Enzo	Classic Cars	3619    112.21
#	2003 Harley-Davidson Eagle Drag Bike    Motorcycles	  5582    102.64
#	1968 Ford Mustang	Classic Cars    68  	99.23
#	1928 Mercedes-Benz SSK	Vintage Cars    548 	96.19
#lowest 
#	1936 Mercedes Benz 500k Roadster	Vintage Cars   2081	  19.28
#	Boeing X-32A JSF	Planes   4857	16.89
#	1930 Buick Marquette Phaeton	Vintage Cars    7062	16.58
#	1982 Ducati 996 R	Motorcycles		9214   16.09
#	1939 Chevrolet Deluxe Coupe 	Vintage Cars    7332	10.62

#Finding highest and lowest selling product vs profit earned with it
SELECT productName, productLine, SUM(quantityOrdered) AS totalOrders,
SUM(quantityOrdered*priceEach - quantityOrdered*buyPrice) AS trueProfit
FROM productsale
GROUP BY quantityInStock
ORDER BY totalOrders DESC;
#highest order- 
#   1992 Ferrari 360 Spider red 	Classic Cars	1808	135996.78
#	1937 Lincoln Berline	Vintage Cars	1111	35214.70
#	American Airlines: MD-11S	Planes	1085	32400.98
#	1941 Chevrolet Special Deluxe Cabriolet	Vintage Cars	1076	33049.37
#	1930 Buick Marquette Phaeton	Vintage Cars	1074	12536.80
#lowest order- 
#	1999 Indy 500 Monte Carlo SS	Classic Cars	855 	52240.32
#	1911 Ford Town Car	Vintage Cars	832 	17601.17
#	1936 Mercedes Benz 500k Roadster	Vintage Cars	824 	11841.39
#	1970 Chevy Chevelle SS 454	Classic Cars	803 	13696.95
#	1957 Ford Thunderbird	Classic Cars	767 	 23862.50

#sorting by true profit high to low vs total quantity ordered 
SELECT productName, productLine,quantityInStock, SUM(quantityOrdered) AS totalOrders,
SUM(quantityOrdered*priceEach - quantityOrdered*buyPrice) AS trueProfit
FROM productsale
GROUP BY quantityInStock
ORDER BY trueProfit DESC;
#highest
#	1992 Ferrari 360 Spider red 	Classic Cars	1808	135996.78
#	1952 Alpine Renault 1300	Classic Cars	961	  95282.58
#	2001 Ferrari Enzo	Classic Cars	1019	93349.65
#	2003 Harley-Davidson Eagle Drag Bike	Motorcycles 	985	81031.30
#	1968 Ford Mustang	Classic Cars	933	72579.26
#lowest
#	1930 Buick Marquette Phaeton	Vintage Cars	1074	12536.80
#	1936 Mercedes Benz 500k Roadster	Vintage Cars	824	 11841.39
#	1982 Ducati 996 R	Motorcycles 	906  	11397.92
#	Boeing X-32A JSF	Planes	 960 	11233.33
#	1939 Chevrolet Deluxe Coupe	Vintage Cars	937 	6904.85

#Create table stockchanges
CREATE TABLE stockChanges
SELECT productName, productLine, quantityInStock, SUM(quantityOrdered),
SUM(quantityOrdered*priceEach-quantityOrdered*buyPrice) AS trueprofit
FROM productsale
GROUP BY productName;

#THE IDEA HERE TO REDUCE THE QUANTITY OF STOCK TO MAXIMUM 900-5500 FOR EVERY ITEM AS SUITED
#Setting soft limit/quota 4000 which intuitively seems apt inventory without it being wasteful and occupying too much 
SELECT *,
CASE
WHEN quantityInStock BETWEEN '4000' AND '4500' THEN '-400'
WHEN quantityInStock BETWEEN '4500' AND '5000' THEN '-900'
WHEN quantityInStock BETWEEN '5000' AND '5500' THEN '-1500'
WHEN quantityInStock BETWEEN '5500' AND '6000' THEN '-2000'
WHEN quantityInStock BETWEEN '6000' AND '6500' THEN '-2500'
WHEN quantityInStock BETWEEN '6500' AND '7000' THEN '-3000'
WHEN quantityInStock BETWEEN '7000' AND '7500' THEN '-3500'
WHEN quantityInStock BETWEEN '7500' AND '8000' THEN '-4000'
WHEN quantityInStock BETWEEN '8000' AND '8500' THEN '-4500'
WHEN quantityInStock BETWEEN '8500' AND '9000' THEN '-5000'
WHEN quantityInStock BETWEEN '9000' AND '9500' THEN '-5500'
WHEN quantityInStock BETWEEN '9500' AND '10000' THEN '-6000'
ELSE 'No changes unless specified'
END AS alteration
FROM stockchanges;
#Saving the table as csv 
#By this method we will be reducing 2,19,200 

#Importing alterations table using import wizard and then
SELECT productLine, SUM(quantityInStock) AS Total_stock, SUM(alteration) AS Final_alteration,
SUM(quantityInStock + alteration) AS Final_Stock
FROM alterations
GROUP BY productLine;

#SUGGESTIONS:
##Particularly for 1939 Chevrolet Deluxe Coupe, it yields extremely low profit and we can completely destock it.
##Restock 1960 BSA Gold Star DBD34 and 1997 BMW F650 ST immediately if R&D suggests that there is demand.
##For Boeing X-32A JSF, we can reduce it further since the profit it yields and the orders too is not very high.
##May or May not consider restocking Pont Yacht based on R&D.

#IMPLEMENTATION AND OUTCOME:
#Amount intended to reduce - 219200 + 7733(totyota Supra) - any further increase in stock, approximately 10000
# - leaving extra space for any unforeseen circumstance, 10000 = 2,06,933
#THUS NEW TOTAL STOCK = 555131 -206933 = 348198

#Warehouse D(south) can be vacated and trucks and buses + ships + trains can be transferred to warehouse A (north)
#---------------------------------------------------------------------------------------------
#Will be exporting this table as csv file(WITH SOME ADDITIONS), FOR VISUALISATION(IF ANY)
SELECT *, (quantityOrdered*MSRP - quantityOrdered*buyPrice) AS projectedProfit,
(quantityOrdered*priceEach - quantityOrdered*buyPrice) AS trueprofit
FROM mintclassics.productsale
ORDER BY quantityInStock DESC;
#----------------------------------------------------------------------------------------------