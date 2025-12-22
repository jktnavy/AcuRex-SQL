USE [acurex_sql_db];
GO

DECLARE @masterId BIGINT;

INSERT INTO reference.penurunan_risiko (informasi_penurunan_risiko, created_by, keterangan)
VALUES ('3-2025', 1, 'Contoh data awal (seed)');

SET @masterId = SCOPE_IDENTITY();

-- kolom dinamis contoh: 1..5
INSERT INTO reference.penurunan_risiko_column (penurunan_risiko_id, nama_kolom, urutan, created_by)
VALUES
(@masterId, '1', 1, 1),
(@masterId, '2', 2, 1),
(@masterId, '3', 3, 1),
(@masterId, '4', 4, 1),
(@masterId, '5', 5, 1);

-- ambil id kolom
DECLARE @c1 BIGINT = (SELECT id FROM reference.penurunan_risiko_column WHERE penurunan_risiko_id=@masterId AND nama_kolom='1' AND deleted_at IS NULL);
DECLARE @c2 BIGINT = (SELECT id FROM reference.penurunan_risiko_column WHERE penurunan_risiko_id=@masterId AND nama_kolom='2' AND deleted_at IS NULL);
DECLARE @c3 BIGINT = (SELECT id FROM reference.penurunan_risiko_column WHERE penurunan_risiko_id=@masterId AND nama_kolom='3' AND deleted_at IS NULL);
DECLARE @c4 BIGINT = (SELECT id FROM reference.penurunan_risiko_column WHERE penurunan_risiko_id=@masterId AND nama_kolom='4' AND deleted_at IS NULL);
DECLARE @c5 BIGINT = (SELECT id FROM reference.penurunan_risiko_column WHERE penurunan_risiko_id=@masterId AND nama_kolom='5' AND deleted_at IS NULL);

-- trot 0..5, nilai contoh
INSERT INTO reference.penurunan_risiko_rate (penurunan_risiko_id, penurunan_risiko_column_id, trot, nilai, created_by)
VALUES
(@masterId, @c1, 0, 1000.00, 1), (@masterId, @c2, 0, 1000.00, 1), (@masterId, @c3, 0, 1000.00, 1), (@masterId, @c4, 0, 1000.00, 1), (@masterId, @c5, 0, 1000.00, 1),
(@masterId, @c1, 1, 924.92, 1),  (@masterId, @c2, 1, 966.63, 1),  (@masterId, @c3, 1, 980.31, 1),  (@masterId, @c4, 1, 986.98, 1),  (@masterId, @c5, 1, 990.85, 1),
(@masterId, @c1, 2, 848.44, 1),  (@masterId, @c2, 2, 932.64, 1),  (@masterId, @c3, 2, 960.25, 1),  (@masterId, @c4, 2, 973.71, 1),  (@masterId, @c5, 2, 981.53, 1),
(@masterId, @c1, 3, 770.51, 1),  (@masterId, @c2, 3, 898.01, 1),  (@masterId, @c3, 3, 939.81, 1),  (@masterId, @c4, 3, 960.20, 1),  (@masterId, @c5, 3, 972.04, 1),
(@masterId, @c1, 4, 691.13, 1),  (@masterId, @c2, 4, 862.72, 1),  (@masterId, @c3, 4, 918.99, 1),  (@masterId, @c4, 4, 946.43, 1),  (@masterId, @c5, 4, 962.37, 1),
(@masterId, @c1, 5, 610.26, 1),  (@masterId, @c2, 5, 826.78, 1),  (@masterId, @c3, 5, 897.77, 1),  (@masterId, @c4, 5, 932.40, 1),  (@masterId, @c5, 5, 952.51, 1);
GO
