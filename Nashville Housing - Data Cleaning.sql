/*

Cleaning Data in SQL Queries

 */
 
-- Exploring overall data 
SELECT 
  * 
FROM 
  PUBLIC."Nashville_Housing";
----------------------------------------------------------------------------------------------

/* Standardizing Date Format */
SELECT 
  "SaleDate", 
  CAST("SaleDate" AS date) 
FROM 
  PUBLIC."Nashville_Housing";
  
UPDATE 
  PUBLIC."Nashville_Housing" 
SET 
  "SaleDate" = CAST("SaleDate" AS date);
----------------------------------------------------------------------------------------------

/* Populate Property Address data */
-- Looking at some NULL values in PropertyAddress column
SELECT 
  * 
FROM 
  PUBLIC."Nashville_Housing" 
WHERE 
  "PropertyAddress" IS NULL 
ORDER BY 
  "ParcelID";
  
-- Looking for blanks in PropertyAddress column that could be filled out with other data where it has same ParecelID but different UniqueID (If UniqueID is the same, then it should be deleted later when removing duplicates.)
SELECT 
  A."ParcelID", 
  A."PropertyAddress", 
  B."ParcelID", 
  B."PropertyAddress", 
  CASE WHEN A."PropertyAddress" IS NULL THEN B."PropertyAddress" END 
FROM 
  PUBLIC."Nashville_Housing" A 
  JOIN PUBLIC."Nashville_Housing" B ON A."ParcelID" = B."ParcelID" 
  AND A."UniqueID" != B."UniqueID" 
WHERE 
  A."PropertyAddress" IS NULL;
  
UPDATE 
  PUBLIC."Nashville_Housing" 
SET 
  "PropertyAddress" = CASE WHEN A."PropertyAddress" IS NULL THEN B."PropertyAddress" END 
FROM 
  PUBLIC."Nashville_Housing" A 
  JOIN PUBLIC."Nashville_Housing" B ON A."ParcelID" = B."ParcelID" 
  AND A."UniqueID" != B."UniqueID" 
WHERE 
  A."PropertyAddress" IS NULL;
----------------------------------------------------------------------------------------------

/* Breaking out Address into Individual Columns (Address, City, State) */
-- Breaking Address by a delimiter(,)
Select 
  Substring(
    "PropertyAddress", 
    1, 
    position(',' in "PropertyAddress")-1
  ) AS Address1, 
  Substring(
    "PropertyAddress", 
    position(',' in "PropertyAddress")+ 1, 
    LENGTH("PropertyAddress")
  ) AS Address2 
From 
  public."Nashville_Housing";
  
-- Creating and Updating columns
Alter Table 
  public."Nashville_Housing" 
Add 
  PropertyAddress_Address VARCHAR(255);
Update 
  public."Nashville_Housing" 
SET 
  PropertyAddress_Address = Substring(
    "PropertyAddress", 
    1, 
    position(',' in "PropertyAddress")-1
  );
  
Alter Table 
  public."Nashville_Housing" 
Add 
  PropertyAddress_City VARCHAR(255);
Update 
  public."Nashville_Housing" 
SET 
  PropertyAddress_City = Substring(
    "PropertyAddress", 
    position(',' in "PropertyAddress")+ 1, 
    LENGTH("PropertyAddress")
  );
  
-- Same thing for OwnerAddress, but using SPLIT_PART
-- Breaking Address by a delimiter(,)
Select 
  "OwnerAddress", 
  SPLIT_PART("OwnerAddress", ',', 1) AS OwnerAddress_Address, 
  SPLIT_PART("OwnerAddress", ',', 2) AS OwnerAddress_City, 
  SPLIT_PART("OwnerAddress", ',', 3) AS OwnerAddress_State 
From 
  public."Nashville_Housing";
  
-- Creating and Updating columns
Alter Table 
  public."Nashville_Housing" 
Add 
  OwnerAddress_Address VARCHAR(255);
Update 
  public."Nashville_Housing" 
SET 
  OwnerAddress_Address = SPLIT_PART("OwnerAddress", ',', 1);
  
Alter Table 
  public."Nashville_Housing" 
Add 
  OwnerAddress_City VARCHAR(255);
Update 
  public."Nashville_Housing" 
SET 
  OwnerAddress_City = SPLIT_PART("OwnerAddress", ',', 2);
  
Alter Table 
  public."Nashville_Housing" 
Add 
  OwnerAddress_State VARCHAR(255);
Update 
  public."Nashville_Housing" 
SET 
  OwnerAddress_State = SPLIT_PART("OwnerAddress", ',', 3);
  
----------------------------------------------------------------------------------------------

/* Change Y and N to Yes and No in "SoldAsVacant" field */
--Looking at different kinds of answers
Select 
  Distinct("SoldAsVacant"), 
  Count("SoldAsVacant") 
From 
  public."Nashville_Housing" 
Group by 
  "SoldAsVacant";
  
--Changing and Updating "SoldAsVacant" field
Select 
  "SoldAsVacant", 
  Case When "SoldAsVacant" = 'Y' Then 'Yes' When "SoldAsVacant" = 'N' Then 'No' Else "SoldAsVacant" End 
From 
  public."Nashville_Housing";
Update 
  public."Nashville_Housing" 
Set 
  "SoldAsVacant" = Case When "SoldAsVacant" = 'Y' Then 'Yes' When "SoldAsVacant" = 'N' Then 'No' Else "SoldAsVacant" End;
  
----------------------------------------------------------------------------------------------

/* Remove Duplicates */
--Identifying duplicates
With CTE AS (
  Select 
    *, 
    Row_Number() Over(
      Partition By "ParcelID", 
      "PropertyAddress", 
      "SalePrice", 
      "SaleDate", 
      "LegalReference" 
      Order BY 
        "UniqueID"
    ) DuplicateCount 
  From 
    public."Nashville_Housing"
) 
Select 
  * 
From 
  CTE 
Where 
  DuplicateCount > 1;
  
--Removing 104 duplicates
With CTE AS (
  Select 
    *, 
    Row_Number() Over(
      Partition By "ParcelID", 
      "PropertyAddress", 
      "SalePrice", 
      "SaleDate", 
      "LegalReference" 
      Order BY 
        "UniqueID"
    ) DuplicateCount 
  From 
    public."Nashville_Housing"
) 
Delete From 
  public."Nashville_Housing" 
Where 
  "UniqueID" In (
    Select 
      "UniqueID" 
    From 
      CTE 
    Where 
      DuplicateCount > 1
  );
  
----------------------------------------------------------------------------------------------
-- Delete Unused Columns(OwnerAddress & PropertyAddress)
Alter Table 
  public."Nashville_Housing" 
Drop 
  Column If exists "OwnerAddress", 
Drop 
  Column If exists "PropertyAddress";