--import file suing OPENROWSET
USE PortofolioProject;

SELECT *
FROM OPENROWSET (BULK 'C:\Users\USER\Downloads\jabar.JSON', SINGLE_CLOB) import

Declare @JSON varchar(max)
SELECT @JSON=BulkColumn
FROM OPENROWSET (BULK 'C:\Users\USER\Downloads\jabar.JSON', SINGLE_CLOB) import
If (ISJSON(@JSON)=1)
Print 'It is a valid JSON'
ELSE
Print 'Error in JSON format'

--Create table for JSON
IF OBJECT_ID('CovidJabar', 'U') IS NOT NULL
	DROP TABLE CovidJabar;
	GO

CREATE TABLE CovidJabar (
	id	VARCHAR(100) NULL,
	kode_kab INT NULL,
	nama_kab VARCHAR(100) NULL,
	kode_kec VARCHAR(100) NULL,
	nama_kec VARCHAR(100) NULL,
	kode_kel VARCHAR(100) NULL,
	status VARCHAR(100) NULL,
	stage VARCHAR(100) NULL,
	umur DECIMAL NULL,
	gender VARCHAR(20) NULL,
	longitude DECIMAL(6,3) NULL,
	latitude DECIMAL(6,3) NULL,
	tanggal_konfirmasi DATE NULL,
	tanggal_update DATE NULL,
	current_location_type VARCHAR(100) NULL,
	current_location_district_code VARCHAR(100) NULL,
	current_location_subdistrict_code VARCHAR(100) NULL,
	current_location_village_code VARCHAR(100) NULL,
	current_location_address VARCHAR(100) NULL,
	report_source VARCHAR(100) NULL,
	tanggal_update_nasional DATE NULL
);
GO

--Convert JSON output from the variable into SQL Server tables
Declare @JSON varchar(max)
SELECT @JSON=BulkColumn
FROM OPENROWSET (BULK 'C:\Users\USER\Downloads\jabar.JSON', SINGLE_CLOB) import
IF (ISJSON(@JSON) = 1)
	BEGIN
		PRINT 'JSON File is valid';

		INSERT INTO CovidJabar
		SELECT *
		FROM OPENJSON(@JSON, '$.data.content')
		WITH (
			ID	VARCHAR(100) '$.id',
			kode_kab INT '$.kode_kab',
			nama_kab VARCHAR(100) '$.nama_kab',
			kode_kec VARCHAR(100) '$.kode_kec',
			nama_kec VARCHAR(100) '$.nama_kec',
			kode_kel VARCHAR(100) '$.kode_kel',
			status VARCHAR(100) '$.status',
			stage VARCHAR(100) '$.stage',
			umur DECIMAL '$.umur',
			gender VARCHAR(20) '$.gender',
			longitude DECIMAL(6,3) '$.longitude',
			latitude DECIMAL(6,3) '$.latitude',
			tanggal_konfirmasi DATE '$.tanggal_konfirmasi',
			tanggal_update DATE '$.tanggal_update',
			current_location_type VARCHAR(100) '$.current_location_type',
			current_location_district_code VARCHAR(100) '$.current_location_district_code',
			current_location_subdistrict_code VARCHAR(100) '$.current_location_subdistrict_code',
			current_location_village_code VARCHAR(100) '$.current_location_village_code',
			current_location_address VARCHAR(100) '$.current_location_address',
			report_source VARCHAR(100) '$.report_source',
			tanggal_update_nasional DATE '$.tanggal_update_nasional'
		)
	END
ELSE
	BEGIN
		PRINT 'JSON File is invalid';
	END

-- Tableau #1 - Covid terhadap umur dan gender// Covid with age and gender
SELECT umur, gender
FROM PortofolioProject.dbo.CovidJabar
WHERE gender IS NOT NULL

-- Tableau #2 - tanggal konfirmasi untuk jumlah// confirmation date to see the numbers thoughout the year
SELECT tanggal_konfirmasi, tanggal_update_nasional
FROM PortofolioProject.dbo.CovidJabar
ORDER BY tanggal_konfirmasi

-- Tableau #3 - Covid based on location// berdasarkan lokasi kabupaten dan kecamatan
SELECT nama_kab, nama_kec
FROM PortofolioProject.dbo.CovidJabar
--Muncul nama_kec yang kosong, perlu diisi, bisa pakai berdasarkan longitude dan latitude
--There are empty nama_kec data, need to be fill, use location based on longitude and latitude
SELECT nama_kab, nama_kec, longitude, latitude
FROM PortofolioProject.dbo.CovidJabar
--to catch the empty box//sekarang untuk menangkap box yang kosong
SELECT a.nama_kec, a.longitude, b.nama_kec, b.longitude, ISNULL(NULLIF(a.nama_kec, ''), b.nama_kec)
FROM PortofolioProject.dbo.CovidJabar a
JOIN PortofolioProject.dbo.CovidJabar b
	ON a.longitude = b.longitude
	AND a.latitude = b.latitude
	AND a.nama_kec <> b.nama_kec
WHERE a.nama_kec = ''

UPDATE a
SET nama_kec = ISNULL(NULLIF(a.nama_kec, ''), b.nama_kec)
FROM PortofolioProject.dbo.CovidJabar a
JOIN PortofolioProject.dbo.CovidJabar b
	ON a.longitude = b.longitude
	AND a.latitude = b.latitude
	AND a.nama_kec <> b.nama_kec
WHERE a.nama_kec = ''
