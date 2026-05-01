-- =====================================================
-- DOLANDIRICILIK TESPIT SISTEMI
-- Veritabani Yonetimi Donem Projesi
-- =====================================================

-- =====================================================
-- 1. TABLOLARI OLUSTURMA (DDL)
-- =====================================================

-- Roller Tablosu
CREATE TABLE Roller (
    RolID INT PRIMARY KEY IDENTITY(1,1),
    RolAdi NVARCHAR(50) NOT NULL
);

-- Kullanicilar Tablosu
CREATE TABLE Kullanicilar (
    KullaniciID INT PRIMARY KEY IDENTITY(1,1),
    AdSoyad NVARCHAR(100) NOT NULL,
    Eposta NVARCHAR(100) UNIQUE NOT NULL,
    Sifre NVARCHAR(255) NOT NULL,
    RolID INT,
    CONSTRAINT FK_Kullanici_Rol FOREIGN KEY (RolID)
    REFERENCES Roller(RolID)
);

-- Hesaplar Tablosu
CREATE TABLE Hesaplar (
    HesapID INT PRIMARY KEY IDENTITY(1,1),
    KullaniciID INT,
    Bakiye DECIMAL(18,2) DEFAULT 0,
    HesapTuru NVARCHAR(30),
    OlusturulmaTarihi DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Hesap_Kullanici FOREIGN KEY (KullaniciID)
    REFERENCES Kullanicilar(KullaniciID)
);

-- Islemler Tablosu
CREATE TABLE Islemler (
    IslemID INT PRIMARY KEY IDENTITY(1,1),
    GonderenHesapID INT,
    AliciHesapID INT,
    Miktar DECIMAL(18,2) NOT NULL,
    IslemTarihi DATETIME DEFAULT GETDATE(),
    Konum NVARCHAR(100),
    CONSTRAINT FK_Gonderen FOREIGN KEY (GonderenHesapID)
    REFERENCES Hesaplar(HesapID),

    CONSTRAINT FK_Alici FOREIGN KEY (AliciHesapID)
    REFERENCES Hesaplar(HesapID)
);

-- Supheli Islem Uyarilari
CREATE TABLE DolandiricilikUyarilari (
    UyariID INT PRIMARY KEY IDENTITY(1,1),
    IslemID INT,
    RiskPuani INT CHECK (RiskPuani BETWEEN 0 AND 100),
    Durum NVARCHAR(30) DEFAULT 'Beklemede',
    TespitTarihi DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Uyari_Islem FOREIGN KEY (IslemID)
    REFERENCES Islemler(IslemID)
);
GO


-- =====================================================
-- 2. TRIGGER
-- 10.000 TL üzeri işlemleri otomatik riskli işaretler
-- =====================================================

CREATE TRIGGER trg_DolandiricilikKontrol
ON Islemler
AFTER INSERT
AS
BEGIN

    INSERT INTO DolandiricilikUyarilari
    (IslemID, RiskPuani, Durum)

    SELECT
        IslemID,
        85,
        'Yuksek Risk'
    FROM inserted
    WHERE Miktar > 10000

END;
GO


-- =====================================================
-- 3. STORED PROCEDURE
-- Riskli işlemleri listeleme
-- =====================================================

CREATE PROCEDURE sp_RiskliIslemleriListele
AS
BEGIN

    SELECT
        D.UyariID,
        K.AdSoyad,
        I.Miktar,
        D.RiskPuani,
        D.Durum,
        D.TespitTarihi

    FROM DolandiricilikUyarilari D
    JOIN Islemler I
        ON D.IslemID = I.IslemID
    JOIN Hesaplar H
        ON I.GonderenHesapID = H.HesapID
    JOIN Kullanicilar K
        ON H.KullaniciID = K.KullaniciID

END;
GO


-- =====================================================
-- 4. FUNCTION
-- Kullanıcının toplam gönderdiği para
-- =====================================================

CREATE FUNCTION fn_ToplamIslemTutari
(
    @KullaniciID INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN

    DECLARE @Toplam DECIMAL(18,2)

    SELECT
        @Toplam = SUM(I.Miktar)
    FROM Islemler I
    JOIN Hesaplar H
        ON I.GonderenHesapID = H.HesapID
    WHERE H.KullaniciID = @KullaniciID

    RETURN ISNULL(@Toplam,0)

END;
GO


-- =====================================================
-- 5. ORNEK VERILER (INSERT)
-- =====================================================

-- Roller
INSERT INTO Roller (RolAdi)
VALUES ('Admin'), ('Musteri');

-- Kullanicilar
INSERT INTO Kullanicilar
(AdSoyad,Eposta,Sifre,RolID)
VALUES
('Sude Demir','sudedemmir@mail.com','sifre123',2),
('Akin Onursoz','akon@mail.com','987654',2),
('Bayrak Yilmaz','bayyil@mail.com','bayY234',2);

-- Hesaplar
INSERT INTO Hesaplar
(KullaniciID,Bakiye,HesapTuru)
VALUES
(1,15000,'Vadesiz'),
(2,5000,'Vadesiz'),
(3,20000,'Mevduat');

-- Islemler
INSERT INTO Islemler
(GonderenHesapID,AliciHesapID,Miktar,Konum)
VALUES
(1,2,500,'Izmir'),        -- Normal işlem
(3,1,12500,'Ankara');    -- Riskli işlem (Trigger çalışır)
GO


-- =====================================================
-- 6. UPDATE ORNEGI
-- Uyarı durumu güncelleme
-- =====================================================

UPDATE DolandiricilikUyarilari
SET Durum = 'Incelendi'
WHERE UyariID = 1;


-- =====================================================
-- 7. DELETE ORNEGI
-- Örnek işlem silme
-- =====================================================

DELETE FROM Islemler
WHERE IslemID = 1;


-- =====================================================
-- 8. GELISMIS SORGULAR
-- =====================================================

-- Hangi kullanıcı ne kadar işlem yapmış?
SELECT
    K.AdSoyad,
    COUNT(I.IslemID) AS ToplamIslemSayisi,
    SUM(I.Miktar) AS ToplamTutar

FROM Kullanicilar K
JOIN Hesaplar H
    ON K.KullaniciID = H.KullaniciID
JOIN Islemler I
    ON H.HesapID = I.GonderenHesapID

GROUP BY K.AdSoyad
HAVING SUM(I.Miktar) > 1000;


-- Riskli işlemleri yapan kişiler
SELECT
    K.AdSoyad,
    I.Miktar,
    D.RiskPuani,
    D.Durum

FROM DolandiricilikUyarilari D
JOIN Islemler I
    ON D.IslemID = I.IslemID
JOIN Hesaplar H
    ON I.GonderenHesapID = H.HesapID
JOIN Kullanicilar K
    ON H.KullaniciID = K.KullaniciID;


-- Son 30 günde en çok işlem yapan kullanıcı
SELECT TOP 1
    K.AdSoyad,
    COUNT(I.IslemID) AS IslemSayisi

FROM Kullanicilar K
JOIN Hesaplar H
    ON K.KullaniciID = H.KullaniciID
JOIN Islemler I
    ON H.HesapID = I.GonderenHesapID

WHERE I.IslemTarihi >= DATEADD(DAY,-30,GETDATE())

GROUP BY K.AdSoyad
ORDER BY IslemSayisi DESC;


-- =====================================================
-- 9. PROCEDURE ÇALIŞTIRMA
-- =====================================================

EXEC sp_RiskliIslemleriListele;


-- =====================================================
-- 10. FUNCTION ÇAĞIRMA
-- =====================================================

SELECT dbo.fn_ToplamIslemTutari(3) AS ToplamIslemTutari;


-- =====================================================
-- 11. TÜM TABLOLARI GOSTER
-- =====================================================

SELECT * FROM Roller;
SELECT * FROM Kullanicilar;
SELECT * FROM Hesaplar;
SELECT * FROM Islemler;
SELECT * FROM DolandiricilikUyarilari;