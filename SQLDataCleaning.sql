/*

Project: Cleaning Data in SQL

In this project, I looked at housing data from Nashville and cleaned it to make it more readable. 
Columns include UniqueID, ParcelID, Address, Sales Data, Cost of Home, Owner, etc. 

*/


Select *
From PortfolioProject.dbo.NashvilleHousing

------------------------------------------------------

/*

Objective: Standardize Date Format

First, I standardized the sales date column for the database. The sales date information was far too specific and meaningless, 
as it included a lot of zeroes and implied that each sale had occurred precisely at midnight, so I started by getting rid of 
all that. I used CONVERT to achieve this goal. For some reason, my update to the existing column didn’t work exactly as expected, 
so I used ALTER TABLE to add a new column (saleDateConverted) in liu of permanently changing the existing column. 

*/

Select SaleDateConverted, CONVERT(Date,SaleDate)
From PortfolioProject.dbo.NashvilleHousing

Update PortfolioProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- Since the above code doesn't update properly

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add SaleDateConverted Date;

Update PortfolioProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


------------------------------------------------------

/*

Objective: Populate Property Address Data

Next, I populated the property address data, which initially included some null values in the column. I then looked at all the 
information for each entity whose property address was null. When looking at all the data, I noticed that some rows had the same ParcelID. 
It occurred to me that I might be able to use ParcelID to populate some property address data, in case some of these duplicates contain null values.
This was correct. I used a self join to formalize this juxtaposition (on Parcel ID being equivalent and Unique ID being non-equivalent). 
I then filtered the results such that, when a duplicate ParcelID is null, the property address from the other row is added to a new column. 
I then updated the previous column including null values.

*/

Select *
From PortfolioProject.dbo.NashvilleHousing
Order by ParcelID


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null



------------------------------------------------------
/*

Objective: Breaking out Address Into Individual Columns (Address, City, State)

Next, I decided to break the address data into individual columns, since the PropertyAddress column included both address and the city. 
Luckily, each entry had a comma as a delimiter. I used CHARINDEX to look for ‘,’  within PropertyAddress to get only the address 
(omitting everything beyond the comma by subtracting 1). Then I populated new column City using the same logic (from the ‘ ,’ plus 1 
through the length of the PropertyAddress). Then, I created two new columns, PropertySplitAddress and PropertySplitCity, and populated 
those columns with the relevant data.

*/

Select PropertyAddress
From PortfolioProject.dbo.NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID


SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address
From PortfolioProject.dbo.NashvilleHousing



ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)



ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

/*

Objective: Breaking out OwnerAddress Into Individual Columns (Address, City, State)

Next, I tackled the same problem in the OwnerAddress, this time using a different method. Instead of substrings, 
I used ParseName for this. ParseName looks for periods by default, so I internally switched each ‘,’ for a ‘.’. 
ParseName works backwards, so I did each section in reverse order (3, 2, 1). Then, I created new columns
like I did previously for the PropertyAddress. 


*/

Select OwnerAddress
From PortfolioProject.dbo.NashvilleHousing



Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From PortfolioProject.dbo.NashvilleHousing



ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)



ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)




------------------------------------------------------


/* 

Objective: Change Y and N to Yes and No in "Sold as Vacant" field

Next, I decided to change each “Y” to “Yes” and each “N” to “No” within the Sold As Vacant field for consistency’s sake 
(since “Yes” and “No” were vastly more populated in the original data). I used CASE to create a When-Then (if then) relationship 
to catch all the stragglers and then updated the database. 

*/


Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2




Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	When SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
From PortfolioProject.dbo.NashvilleHousing



Update PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	When SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

------------------------------------------------------

/* 

Objective: Remove Duplicates

Next, I removed duplicates by creating a CTE and then using some window functions to find those duplicates. 
I started by writing the query and then putting it into a CTE afterwards. I used ROW_NUMBER() to identify 
duplicates and DELETE to remove them. 


*/


WITH RowNumCTE AS( 
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
From PortfolioProject.dbo.NashvilleHousing
)


Select *
From RowNumCTE
Where row_num > 1

------------------------------------------------------


/*

Objective: Delete Unused Columns

Finally, I removed some columns I deemed to be unnecessary for the data. I used ALTER TABLE 
to DROP OwnerAddress, TaxDistrict, PropertyAddress, and SaleDate (which were unnecessary fields 
because all the relevant data was split into other fields in previous queries).  

*/

Select *
From PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate

