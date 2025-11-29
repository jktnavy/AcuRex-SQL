-- C:\Users\heden\Documents\Web Project 2022\Cadangan Project\GPV NON CAPTIVE\PK' (Margin 10%)\Pembiayaan Tetap Margin 10%.xlsx

declare @namaProduk varchar(50) = 'Pembiayaan Tetap Margin 10%'
declare @masaAsuransiBulan tinyint = 30
declare @masaAsuransiTahun tinyint = @masaAsuransiBulan / 12
declare @usiaMasuk tinyint = 30
declare @uangPertanggunganAwal decimal(18,2) = 1000000000.00
declare @tingkatMarjinPremi decimal(18,2) = 0.10

declare @quotaShareJmas decimal(18,2) = 0.00
declare @quotaShareReas decimal(18,2) = 0.00

declare @interestRate decimal(18,2) = 0.00
declare @iBulanan decimal(18,2) = 0.00

declare @mortalita varchar(50) = 'reas-unisex'

declare @lapseRateTahunKe_1 decimal(18,2) = 0.00
declare @lapseRateTahunKe_2 decimal(18,2) = 0.00
declare @lapseRateTahunKe_3 decimal(18,2) = 0.00
declare @lapseRateTahunKe_4 decimal(18,2) = 0.00
declare @lapseRateTahunKe_5_dst decimal(18,2) = 0.00


select @namaProduk as 'nama_produk',
       @masaAsuransiBulan as 'masa_asuransi_bulan',
       @masaAsuransiTahun as 'masa_asuransi_tahun',
       @usiaMasuk as 'usia_masuk',
       @uangPertanggunganAwal as 'uang_pertanggungan_awal',
       @tingkatMarjinPremi as 'tingkat_marjin_premi',
       @quotaShareJmas as 'quota_share_jmas',
       @quotaShareReas as 'quota_share_reas',
       @interestRate as 'interest_rate',
       @iBulanan as 'i_bulanan',
       @mortalita as 'mortalita',
       @lapseRateTahunKe_1 as 'lapse_rate_tahun_ke_1',
       @lapseRateTahunKe_2 as 'lapse_rate_tahun_ke_2',
       @lapseRateTahunKe_3 as 'lapse_rate_tahun_ke_3',
       @lapseRateTahunKe_4 as 'lapse_rate_tahun_ke_4',
       @lapseRateTahunKe_5_dst as 'lapse_rate_tahun_ke_5_dst'

-- catatan:  table #umurPolis digabungkan dengan kolom yang ada di dokumen ilustrasi "Pembiayaan Tetap Margin 10%"
create table #umurPolis (
  bulan_polis_ke_ tinyint,
  tahun_polis_ke_ tinyint
)

insert into #umurPolis (bulan_polis_ke_, tahun_polis_ke_)
select bulan_polis_ke_, ceiling(cast(bulan_polis_ke_ as float) / 12) as tahun_polis_ke_
from (
  select top (@masaAsuransiBulan) row_number() over (order by (select null)) as bulan_polis_ke_
  from master.dbo.spt_values
) as bulanData


-- kolom yang ada di dokumen ilustrasi "Pembiayaan Tetap Margin 10%"
alter table #umurPolis 
  add usia tinyint null
    , qx decimal(18,10) null
    , lapse_rate decimal(18,5) null
    , dx decimal(18,2) null
    , dw decimal(18,8) null
    , polis_inforce_awal decimal(18,9) null
    , polis_inforce_akhir decimal(18,9) null

    , iuran_tabarru decimal(18,0) null
    , kontribusi_reas decimal(18,0) null
    , manfaat_kematian decimal(18,0) null
    , manfaat_pengunduran decimal(18,0) null
    , cadangan decimal(18,0) null
    , kenaikan_cadangan decimal(18,0) null
    , surplus_underwriting decimal(18,0) null
    , dana_tabarru decimal(18,0) null
    , peserta decimal(18,0) null
    , pengelola decimal(18,0) null

    , pv_manfaat decimal(18,0) null
    , pv_interest decimal(18,8) null
    , tbd_1 decimal(18,0) null
    , tbd_2 decimal(18,0) null
    , cadangan_1 decimal(18,0) null

    , cv decimal(18,0) null
    , tbd_4 decimal(18,0) null


update #umurPolis
set usia = 
  case 
    when bulan_polis_ke_ = 0 then 0
    else @usiaMasuk + tahun_polis_ke_ - 1
  end

-- end #umurPolis ( bulan_polis_ke_, tahun_polis_ke_, usia )


-- C:\Users\heden\Documents\Web Project 2022\Cadangan Project\GPV NON CAPTIVE\PK' (Margin 10%)\Asumsi Perhitungan GPV Margin 10%.xlsx
declare @faktorPengaliMortalita decimal(18,2) = 110 / 100.0

-- Deklarasi variabel tabel
declare @kategoriMoralita table (
    id int identity(1,1),
    nama_kategori nvarchar(100),
    jenis_moralita nvarchar(50)
);

-- Insert data kategori moralita lengkap
insert into @kategoriMoralita (nama_kategori, jenis_moralita)
values
    ('pria', 'gender-specific'),
    ('wanita', 'gender-specific'),
    ('unisex', 'gender-neutral'),
    ('reas-pria', 'gender-specific'),
    ('reas-wanita', 'gender-specific'),
    ('reas-unisex', 'gender-neutral'),
    ('sport-pria', 'gender-specific'),
    ('sport-wanita', 'gender-specific'),
    ('sport-unisex', 'gender-neutral'),
    ('casual-pria', 'gender-specific'),
    ('casual-wanita', 'gender-specific'),
    ('casual-unisex', 'gender-neutral'),
    ('anak-pria', 'gender-specific'),
    ('anak-wanita', 'gender-specific'),
    ('anak-unisex', 'gender-neutral');

-- Cek isi tabel
--select * from @kategoriMoralita;

create table #asumsi_perhitungan_gpv_margin_10 (
  trot int,
  laki_laki decimal(18,5),
  perempuan decimal(18,5),
  unisex decimal(18,5),
  reas_pria decimal(18,5),
  reas_unisex decimal(18,5)
)

insert into #asumsi_perhitungan_gpv_margin_10 (trot, laki_laki, perempuan)
values
(0,   0.00802, 0.00370),
(1,   0.00079, 0.00056),
(2,   0.00063, 0.00042),
(3,   0.00051, 0.00033),
(4,   0.00043, 0.00028),
(5,   0.00038, 0.00027),
(6,   0.00034, 0.00030),
(7,   0.00031, 0.00031),
(8,   0.00029, 0.00030),
(9,   0.00028, 0.00028),
(10,  0.00027, 0.00025),
(11,  0.00027, 0.00024),
(12,  0.00026, 0.00026),
(13,  0.00026, 0.00028),
(14,  0.00027, 0.00029),
(15,  0.00029, 0.00028),
(16,  0.00030, 0.00025),
(17,  0.00032, 0.00024),
(18,  0.00036, 0.00023),
(19,  0.00041, 0.00024),
(20,  0.00049, 0.00026),
(21,  0.00059, 0.00029),
(22,  0.00069, 0.00033),
(23,  0.00077, 0.00037),
(24,  0.00083, 0.00039),
(25,  0.00085, 0.00042),
(26,  0.00083, 0.00044),
(27,  0.00079, 0.00046),
(28,  0.00075, 0.00048),
(29,  0.00074, 0.00051),
(30,  0.00076, 0.00054),
(31,  0.00080, 0.00057),
(32,  0.00083, 0.00060),
(33,  0.00084, 0.00062),
(34,  0.00086, 0.00064),
(35,  0.00091, 0.00067),
(36,  0.00099, 0.00074),
(37,  0.00109, 0.00084),
(38,  0.00120, 0.00093),
(39,  0.00135, 0.00104),
(40,  0.00153, 0.00114),
(41,  0.00175, 0.00126),
(42,  0.00196, 0.00141),
(43,  0.00219, 0.00158),
(44,  0.00246, 0.00175),
(45,  0.00279, 0.00193),
(46,  0.00318, 0.00214),
(47,  0.00363, 0.00239),
(48,  0.00414, 0.00268),
(49,  0.00471, 0.00299),
(50,  0.00538, 0.00334),
(51,  0.00615, 0.00374),
(52,  0.00699, 0.00422),
(53,  0.00784, 0.00479),
(54,  0.00872, 0.00542),
(55,  0.00961, 0.00607),
(56,  0.01051, 0.00669),
(57,  0.01142, 0.00725),
(58,  0.01232, 0.00776),
(59,  0.01322, 0.00826),
(60,  0.01417, 0.00877),
(61,  0.01521, 0.00936),
(62,  0.01639, 0.01004),
(63,  0.01773, 0.01104),
(64,  0.01926, 0.01214),
(65,  0.02100, 0.01334),
(66,  0.02288, 0.01466),
(67,  0.02486, 0.01612),
(68,  0.02702, 0.01771),
(69,  0.02921, 0.01947),
(70,  0.03182, 0.02121),
(71,  0.03473, 0.02319),
(72,  0.03861, 0.02539),
(73,  0.04264, 0.02778),
(74,  0.04687, 0.03042),
(75,  0.05155, 0.03330),
(76,  0.05664, 0.03646),
(77,  0.06254, 0.03991),
(78,  0.06942, 0.04372),
(79,  0.07734, 0.04789),
(80,  0.08597, 0.05247),
(81,  0.09577, 0.05877),
(82,  0.10593, 0.06579),
(83,  0.11683, 0.07284),
(84,  0.12888, 0.08061),
(85,  0.14241, 0.08925),
(86,  0.15738, 0.09713),
(87,  0.17368, 0.10893),
(88,  0.19110, 0.12131),
(89,  0.20945, 0.13450),
(90,  0.22853, 0.14645),
(91,  0.24638, 0.15243),
(92,  0.26496, 0.16454),
(93,  0.28450, 0.18235),
(94,  0.30511, 0.20488),
(95,  0.32682, 0.23305),
(96,  0.34662, 0.25962),
(97,  0.36770, 0.28720),
(98,  0.39016, 0.29173),
(99,  0.41413, 0.30759),
(100, 0.43974, 0.33241),
(101, 0.45994, 0.35918),
(102, 0.48143, 0.38871),
(103, 0.50431, 0.42124),
(104, 0.52864, 0.45705),
(105, 0.55450, 0.49580),
(106, 0.58198, 0.53553),
(107, 0.61119, 0.57626),
(108, 0.64222, 0.61725),
(109, 0.67518, 0.65996),
(110, 0.71016, 0.70366),
(111, 1.00000, 1.00000)

create table #temp_rate_reas_kumpulan (
    trot int,
    rate_reas_kumpulan decimal(18,6) null
)

insert into #temp_rate_reas_kumpulan (trot, rate_reas_kumpulan) values
    (0, NULL), (1, NULL), (2, NULL), (3, NULL), (4, NULL), (5, NULL),
    (6, NULL), (7, NULL), (8, NULL), (9, NULL), (10, NULL), (11, NULL),
    (12, NULL), (13, NULL), (14, NULL), (15, NULL), (16, NULL),
    (17, 0.00061), (18, 0.00061), (19, 0.00061), (20, 0.00061),
    (21, 0.00061), (22, 0.00061), (23, 0.00061), (24, 0.00061),
    (25, 0.00061), (26, 0.00061), (27, 0.00061), (28, 0.00064),
    (29, 0.00065), (30, 0.00066), (31, 0.00068), (32, 0.00069),
    (33, 0.00072), (34, 0.00077), (35, 0.00084), (36, 0.00093),
    (37, 0.00101), (38, 0.00108), (39, 0.00117), (40, 0.00127),
    (41, 0.00138), (42, 0.0015), (43, 0.00162), (44, 0.00176),
    (45, 0.0019), (46, 0.00207), (47, 0.00223), (48, 0.00241),
    (49, 0.00261), (50, 0.00281), (51, 0.00306), (52, 0.00334),
    (53, 0.00366), (54, 0.00389), (55, 0.00413), (56, 0.00449),
    (57, 0.0049), (58, 0.00544), (59, 0.00598), (60, 0.00658),
    (61, 0.00726), (62, 0.00806), (63, 0.00885), (64, 0.00972),
    (65, 0.0114), (66, 0.01246), (67, 0.01358), (68, 0.01481),
    (69, 0.01594), (70, 0.01643), (71, 0.01724), (72, 0.01898),
    (73, 0.02096), (74, 0.02306), (75, 0.0252), (76, 0.02769),
    (77, 0.03028), (78, 0.03294), (79, 0.03575), (80, 0.03764),
    (81, NULL), (82, NULL), (83, NULL), (84, NULL), (85, NULL),
    (86, NULL), (87, NULL), (88, NULL), (89, NULL), (90, NULL),
    (91, NULL), (92, NULL), (93, NULL), (94, NULL), (95, NULL),
    (96, NULL), (97, NULL), (98, NULL), (99, NULL), (100, NULL),
    (101, NULL), (102, NULL), (103, NULL), (104, NULL), (105, NULL),
    (106, NULL), (107, NULL), (108, NULL), (109, NULL), (110, NULL),
    (111, NULL);


update #asumsi_perhitungan_gpv_margin_10
set unisex = ( laki_laki + perempuan ) / 2.0

update #asumsi_perhitungan_gpv_margin_10
set reas_pria = case when b.rate_reas_kumpulan is null then laki_laki else b.rate_reas_kumpulan end
, reas_unisex = case when b.rate_reas_kumpulan is null then unisex else b.rate_reas_kumpulan end
from #asumsi_perhitungan_gpv_margin_10 a
left join #temp_rate_reas_kumpulan b
on a.trot = b.trot

alter table #asumsi_perhitungan_gpv_margin_10
  add rate_yang_digunakan decimal(18,6) null 

update #asumsi_perhitungan_gpv_margin_10
set rate_yang_digunakan =
	case
		when @faktorPengaliMortalita = 0 then
			case
				when @mortalita = 'pria' then laki_laki
				when @mortalita = 'unisex' then unisex
				when @mortalita = 'reas - pria' then reas_pria
				else reas_unisex
			end
	else
	(
		case 
				when @mortalita = 'pria' then laki_laki
				when @mortalita = 'unisex' then unisex
				when @mortalita = 'reas - pria' then reas_pria
				else reas_unisex
		end
	) * @faktorPengaliMortalita
	end;

update #asumsi_perhitungan_gpv_margin_10
set rate_yang_digunakan =
    case 
        when @faktorPengaliMortalita = 0 then
            case
                when @mortalita = 'pria' then laki_laki
                when @mortalita = 'unisex' then unisex
                when @mortalita = 'reas-pria' then reas_pria
                else reas_unisex
            end
        else
            case
                when @mortalita = 'pria' then laki_laki
                when @mortalita = 'unisex' then unisex
                when @mortalita = 'reas-pria' then reas_pria
                else reas_unisex
            end * @faktorPengaliMortalita
    end;

--select * from #asumsi_perhitungan_gpv_margin_10
--select trot, laki_laki, perempuan, unisex, reas_pria, reas_unisex, rate_yang_digunakan from #asumsi_perhitungan_gpv_margin_10


update #umurPolis
set qx = 
			case
				when a.bulan_polis_ke_ = 0 then 0
				else  1 - power( 1 - ( b.rate_yang_digunakan ), 1.0 / 12 )
				end
from #umurPolis a
left join #asumsi_perhitungan_gpv_margin_10 b
on b.trot = a.usia


/*
update #umurPolis
set qx = b.rate_yang_digunakan
from #umurPolis a
left join #asumsi_perhitungan_gpv_margin_10 b
on b.trot = a.usia
*/

select * from #asumsi_perhitungan_gpv_margin_10
--select * from #temp_rate_reas_kumpulan

select * from #umurPolis


drop table #umurPolis
drop table #asumsi_perhitungan_gpv_margin_10
drop table #temp_rate_reas_kumpulan