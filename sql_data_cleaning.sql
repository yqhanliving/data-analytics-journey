SELECT *
FROM PortfolioProject..NashvilleHousing

-- Standardize Date Format

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate DATE

-- Populate Property Address Data

SELECT a.ParcelID
    , a.PropertyAddress
    , b.PropertyAddress
    , ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing AS a
    JOIN PortfolioProject..NashvilleHousing AS b
        ON a.ParcelID = b.ParcelID
            AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing AS a
    JOIN PortfolioProject..NashvilleHousing AS b
        ON a.ParcelID = b.ParcelID
            AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

-- Break up Address into Individual Columns (Address, City, State)
-- Break up PropertyAddress
SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address
    , SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255)
    , PropertySplitCity NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)
    , PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

-- Break up OwnerAddress
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
    , PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
    , PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255)
    , OwnerSplitCity NVARCHAR(255)
    , OwnerSplitState NVARCHAR(255)

UPDATE NashvilleHousing
    SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
    , OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
    , OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Change Y and N to Yes and No in 'SoldAsVacant' field
SELECT DISTINCT(SoldAsVacant)
    , COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END

-- Remove Duplicates
---- Create cte for filtering duplicate records
WITH cte AS(
    SELECT *
        , ROW_NUMBER() OVER (PARTITION BY ParcelID
            , PropertyAddress
            , SaleDate
            , SalePrice
            , LegalReference
            ORDER BY UniqueID) AS row_num
        FROM NashvilleHousing 
)

---- Test whether the above criteria actually locates duplicate records
SELECT *
FROM NashvilleHousing
WHERE EXISTS (
    SELECT ParcelID
    FROM cte
    WHERE cte.ParcelID = NashvilleHousing.ParcelID
        AND cte.PropertyAddress = NashvilleHousing.PropertyAddress
        AND cte.SaleDate = NashvilleHousing.SaleDate
        AND cte.SalePrice = NashvilleHousing.SalePrice
        AND cte.LegalReference = NashvilleHousing.LegalReference
        AND row_num > 1
)
ORDER BY ParcelID

---- Apply DELETE
WITH cte AS(
    SELECT *
        , ROW_NUMBER() OVER (PARTITION BY ParcelID
            , PropertyAddress
            , SaleDate
            , SalePrice
            , LegalReference
            ORDER BY UniqueID) AS row_num
        FROM NashvilleHousing 
)

DELETE 
FROM cte
WHERE row_num > 1

-- Delete Unuseable Columns
SELECT * 
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress