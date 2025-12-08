USE [acurex_sql_db];
GO

DECLARE @BaseRateId BIGINT;

/* Seed master untuk Ujroh 12.5% */
INSERT INTO reference.base_rate_nasre_ujroh (
    kode,
    nama,
    ujroh_percent,
    usia_min,
    usia_max,
    jangka_waktu_min,
    jangka_waktu_max,
    is_active,
    created_by,
    keterangan
)
VALUES (
    'NASRE_UJROH_12_5',
    'Base Rate Nasre Ujroh 12.5%',
    12.50,
    0,
    80,
    1,
    15,
    1,
    1, -- created_by, silakan ganti dengan user id sistem Anda
    'Seed awal dari file base_rate_nasre_ujroh_12_5_persen'
);

SET @BaseRateId = SCOPE_IDENTITY();

/* CONTOH SEED DETAIL
   Catatan:
   - Gunakan titik (.) sebagai desimal di SQL, bukan koma (,)
   - Ini hanya contoh beberapa baris; data lengkap bisa di-import
     dari Excel ke tabel detail (mis. via script BULK/OPENROWSET
     atau tool import SSMS). */

/* Usia 17, Jangka Waktu 1–5 (contoh) */
INSERT INTO reference.base_rate_nasre_ujroh_detail (
    base_rate_id, usia, jangka_waktu, rate, created_by, keterangan
)
VALUES
    (@BaseRateId, 17,  1, 0.38, 1, NULL),
    (@BaseRateId, 17,  2, 0.73, 1, NULL),
    (@BaseRateId, 17,  3, 1.08, 1, NULL),
    (@BaseRateId, 17,  4, 1.42, 1, NULL),
    (@BaseRateId, 17,  5, 1.76, 1, NULL);

/* Usia 18, Jangka Waktu 1–5 (contoh) */
INSERT INTO reference.base_rate_nasre_ujroh_detail (
    base_rate_id, usia, jangka_waktu, rate, created_by, keterangan
)
VALUES
    (@BaseRateId, 18,  1, 0.38, 1, NULL),
    (@BaseRateId, 18,  2, 0.73, 1, NULL),
    (@BaseRateId, 18,  3, 1.08, 1, NULL),
    (@BaseRateId, 18,  4, 1.42, 1, NULL),
    (@BaseRateId, 18,  5, 1.76, 1, NULL);

/* dst. → lanjutkan sendiri atau buat script import dari Excel */
GO
