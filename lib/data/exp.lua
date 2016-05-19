local datas = {
	[1] = {
		lv = 1,
		HeroExp = 100,
		UpgradeMatNum = 1,
		ImproveMatNum = 1,
		DecomposeMatNum = 1,
		cardStar = 3,
		ImproveLimit = 2,
		starLevel = 1,
		passiveItem = 1,
		passiveExp = 30,
		compos1 = 5250,
		compos2 = 3000,
		compos5 = 1750,
	},
	[2] = {
		lv = 2,
		HeroExp = 200,
		UpgradeMatNum = 1,
		ImproveMatNum = 1,
		DecomposeMatNum = 1,
		cardStar = 7,
		ImproveLimit = 2,
		starLevel = 1,
		passiveItem = 1,
		passiveExp = 72,
		compos1 = 5400,
		compos2 = 2900,
		compos5 = 1700,
	},
	[3] = {
		lv = 3,
		HeroExp = 300,
		UpgradeMatNum = 1,
		ImproveMatNum = 1,
		DecomposeMatNum = 1,
		cardStar = 13,
		ImproveLimit = 2,
		starLevel = 1,
		passiveItem = 1,
		passiveExp = 130,
		compos1 = 5550,
		compos2 = 2800,
		compos5 = 1650,
	},
	[4] = {
		lv = 4,
		HeroExp = 400,
		UpgradeMatNum = 1,
		ImproveMatNum = 1,
		DecomposeMatNum = 1,
		cardStar = 21,
		ImproveLimit = 2,
		starLevel = 1,
		passiveItem = 1,
		passiveExp = 208,
		compos1 = 5700,
		compos2 = 2700,
		compos5 = 1600,
	},
	[5] = {
		lv = 5,
		HeroExp = 500,
		UpgradeMatNum = 2,
		ImproveMatNum = 2,
		DecomposeMatNum = 1,
		cardStar = 31,
		ImproveLimit = 2,
		starLevel = 1,
		passiveItem = 1,
		passiveExp = 310,
		compos1 = 5850,
		compos2 = 2600,
		compos5 = 1550,
	},
	[6] = {
		lv = 6,
		HeroExp = 600,
		UpgradeMatNum = 2,
		ImproveMatNum = 2,
		DecomposeMatNum = 1,
		cardStar = 44,
		ImproveLimit = 2,
		starLevel = 1,
		passiveItem = 1,
		passiveExp = 440,
		compos1 = 6000,
		compos2 = 2500,
		compos5 = 1500,
	},
	[7] = {
		lv = 7,
		HeroExp = 700,
		UpgradeMatNum = 2,
		ImproveMatNum = 2,
		DecomposeMatNum = 1,
		cardStar = 60,
		ImproveLimit = 2,
		starLevel = 1,
		passiveItem = 1,
		passiveExp = 602,
		compos1 = 6150,
		compos2 = 2400,
		compos5 = 1450,
	},
	[8] = {
		lv = 8,
		HeroExp = 800,
		UpgradeMatNum = 2,
		ImproveMatNum = 2,
		DecomposeMatNum = 1,
		cardStar = 80,
		ImproveLimit = 2,
		starLevel = 1,
		passiveItem = 1,
		passiveExp = 800,
		compos1 = 6300,
		compos2 = 2300,
		compos5 = 1400,
	},
	[9] = {
		lv = 9,
		HeroExp = 900,
		UpgradeMatNum = 2,
		ImproveMatNum = 2,
		DecomposeMatNum = 1,
		cardStar = 104,
		ImproveLimit = 2,
		starLevel = 1,
		passiveItem = 1,
		passiveExp = 1038,
		compos1 = 6450,
		compos2 = 2200,
		compos5 = 1350,
	},
	[10] = {
		lv = 10,
		HeroExp = 1000,
		UpgradeMatNum = 3,
		ImproveMatNum = 4,
		DecomposeMatNum = 1,
		cardStar = 132,
		ImproveLimit = 2,
		starLevel = 1,
		passiveItem = 1,
		passiveExp = 1320,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[11] = {
		lv = 11,
		HeroExp = 1100,
		UpgradeMatNum = 3,
		ImproveMatNum = 4,
		DecomposeMatNum = 1,
		cardStar = 165,
		ImproveLimit = 2,
		starLevel = 2,
		passiveItem = 1,
		passiveExp = 1650,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[12] = {
		lv = 12,
		HeroExp = 1200,
		UpgradeMatNum = 3,
		ImproveMatNum = 4,
		DecomposeMatNum = 1,
		cardStar = 203,
		ImproveLimit = 2,
		starLevel = 2,
		passiveItem = 1,
		passiveExp = 2032,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[13] = {
		lv = 13,
		HeroExp = 1300,
		UpgradeMatNum = 3,
		ImproveMatNum = 4,
		DecomposeMatNum = 1,
		cardStar = 247,
		ImproveLimit = 2,
		starLevel = 2,
		passiveItem = 1,
		passiveExp = 2470,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[14] = {
		lv = 14,
		HeroExp = 1400,
		UpgradeMatNum = 3,
		ImproveMatNum = 4,
		DecomposeMatNum = 1,
		cardStar = 297,
		ImproveLimit = 2,
		starLevel = 2,
		passiveItem = 1,
		passiveExp = 2968,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[15] = {
		lv = 15,
		HeroExp = 1500,
		UpgradeMatNum = 4,
		ImproveMatNum = 6,
		DecomposeMatNum = 2,
		cardStar = 353,
		ImproveLimit = 3,
		starLevel = 2,
		passiveItem = 1,
		passiveExp = 3530,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[16] = {
		lv = 16,
		HeroExp = 1600,
		UpgradeMatNum = 4,
		ImproveMatNum = 6,
		DecomposeMatNum = 2,
		cardStar = 0,
		ImproveLimit = 3,
		starLevel = 2,
		passiveItem = 1,
		passiveExp = 4160,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[17] = {
		lv = 17,
		HeroExp = 1700,
		UpgradeMatNum = 4,
		ImproveMatNum = 6,
		DecomposeMatNum = 2,
		cardStar = 0,
		ImproveLimit = 3,
		starLevel = 2,
		passiveItem = 1,
		passiveExp = 4862,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[18] = {
		lv = 18,
		HeroExp = 1800,
		UpgradeMatNum = 4,
		ImproveMatNum = 6,
		DecomposeMatNum = 2,
		cardStar = 0,
		ImproveLimit = 3,
		starLevel = 2,
		passiveItem = 1,
		passiveExp = 5640,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[19] = {
		lv = 19,
		HeroExp = 1900,
		UpgradeMatNum = 4,
		ImproveMatNum = 6,
		DecomposeMatNum = 2,
		cardStar = 0,
		ImproveLimit = 3,
		starLevel = 2,
		passiveItem = 1,
		passiveExp = 6498,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[20] = {
		lv = 20,
		HeroExp = 2000,
		UpgradeMatNum = 5,
		ImproveMatNum = 9,
		DecomposeMatNum = 3,
		cardStar = 0,
		ImproveLimit = 3,
		starLevel = 2,
		passiveItem = 1,
		passiveExp = 7440,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[21] = {
		lv = 21,
		HeroExp = 2100,
		UpgradeMatNum = 5,
		ImproveMatNum = 9,
		DecomposeMatNum = 3,
		cardStar = 0,
		ImproveLimit = 3,
		starLevel = 3,
		passiveItem = 1,
		passiveExp = 8470,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[22] = {
		lv = 22,
		HeroExp = 2200,
		UpgradeMatNum = 5,
		ImproveMatNum = 9,
		DecomposeMatNum = 3,
		cardStar = 0,
		ImproveLimit = 3,
		starLevel = 3,
		passiveItem = 1,
		passiveExp = 9592,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[23] = {
		lv = 23,
		HeroExp = 2300,
		UpgradeMatNum = 5,
		ImproveMatNum = 9,
		DecomposeMatNum = 3,
		cardStar = 0,
		ImproveLimit = 3,
		starLevel = 3,
		passiveItem = 1,
		passiveExp = 10810,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[24] = {
		lv = 24,
		HeroExp = 2400,
		UpgradeMatNum = 5,
		ImproveMatNum = 9,
		DecomposeMatNum = 3,
		cardStar = 0,
		ImproveLimit = 3,
		starLevel = 3,
		passiveItem = 1,
		passiveExp = 12128,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[25] = {
		lv = 25,
		HeroExp = 2500,
		UpgradeMatNum = 6,
		ImproveMatNum = 13,
		DecomposeMatNum = 4,
		cardStar = 0,
		ImproveLimit = 3,
		starLevel = 3,
		passiveItem = 1,
		passiveExp = 13550,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[26] = {
		lv = 26,
		HeroExp = 2600,
		UpgradeMatNum = 6,
		ImproveMatNum = 13,
		DecomposeMatNum = 4,
		cardStar = 0,
		ImproveLimit = 3,
		starLevel = 3,
		passiveItem = 1,
		passiveExp = 15080,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[27] = {
		lv = 27,
		HeroExp = 2700,
		UpgradeMatNum = 6,
		ImproveMatNum = 13,
		DecomposeMatNum = 4,
		cardStar = 0,
		ImproveLimit = 3,
		starLevel = 3,
		passiveItem = 1,
		passiveExp = 16722,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[28] = {
		lv = 28,
		HeroExp = 2800,
		UpgradeMatNum = 6,
		ImproveMatNum = 13,
		DecomposeMatNum = 4,
		cardStar = 0,
		ImproveLimit = 3,
		starLevel = 3,
		passiveItem = 1,
		passiveExp = 18480,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[29] = {
		lv = 29,
		HeroExp = 2900,
		UpgradeMatNum = 6,
		ImproveMatNum = 13,
		DecomposeMatNum = 4,
		cardStar = 0,
		ImproveLimit = 3,
		starLevel = 3,
		passiveItem = 1,
		passiveExp = 20358,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[30] = {
		lv = 30,
		HeroExp = 3000,
		UpgradeMatNum = 7,
		ImproveMatNum = 18,
		DecomposeMatNum = 6,
		cardStar = 0,
		ImproveLimit = 4,
		starLevel = 3,
		passiveItem = 1,
		passiveExp = 22360,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[31] = {
		lv = 31,
		HeroExp = 3100,
		UpgradeMatNum = 7,
		ImproveMatNum = 18,
		DecomposeMatNum = 6,
		cardStar = 0,
		ImproveLimit = 4,
		starLevel = 4,
		passiveItem = 2,
		passiveExp = 24490,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[32] = {
		lv = 32,
		HeroExp = 3200,
		UpgradeMatNum = 7,
		ImproveMatNum = 18,
		DecomposeMatNum = 6,
		cardStar = 0,
		ImproveLimit = 4,
		starLevel = 4,
		passiveItem = 2,
		passiveExp = 26752,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[33] = {
		lv = 33,
		HeroExp = 3300,
		UpgradeMatNum = 7,
		ImproveMatNum = 18,
		DecomposeMatNum = 6,
		cardStar = 0,
		ImproveLimit = 4,
		starLevel = 4,
		passiveItem = 2,
		passiveExp = 29150,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[34] = {
		lv = 34,
		HeroExp = 3400,
		UpgradeMatNum = 7,
		ImproveMatNum = 18,
		DecomposeMatNum = 6,
		cardStar = 0,
		ImproveLimit = 4,
		starLevel = 4,
		passiveItem = 2,
		passiveExp = 31688,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[35] = {
		lv = 35,
		HeroExp = 3500,
		UpgradeMatNum = 8,
		ImproveMatNum = 24,
		DecomposeMatNum = 7,
		cardStar = 0,
		ImproveLimit = 4,
		starLevel = 4,
		passiveItem = 2,
		passiveExp = 34370,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[36] = {
		lv = 36,
		HeroExp = 3600,
		UpgradeMatNum = 8,
		ImproveMatNum = 24,
		DecomposeMatNum = 7,
		cardStar = 0,
		ImproveLimit = 4,
		starLevel = 4,
		passiveItem = 2,
		passiveExp = 37200,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[37] = {
		lv = 37,
		HeroExp = 3700,
		UpgradeMatNum = 8,
		ImproveMatNum = 24,
		DecomposeMatNum = 7,
		cardStar = 0,
		ImproveLimit = 4,
		starLevel = 4,
		passiveItem = 2,
		passiveExp = 40182,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[38] = {
		lv = 38,
		HeroExp = 3800,
		UpgradeMatNum = 8,
		ImproveMatNum = 24,
		DecomposeMatNum = 7,
		cardStar = 0,
		ImproveLimit = 4,
		starLevel = 5,
		passiveItem = 2,
		passiveExp = 43320,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[39] = {
		lv = 39,
		HeroExp = 3900,
		UpgradeMatNum = 8,
		ImproveMatNum = 24,
		DecomposeMatNum = 7,
		cardStar = 0,
		ImproveLimit = 4,
		starLevel = 5,
		passiveItem = 2,
		passiveExp = 46618,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[40] = {
		lv = 40,
		HeroExp = 4000,
		UpgradeMatNum = 9,
		ImproveMatNum = 30,
		DecomposeMatNum = 9,
		cardStar = 0,
		ImproveLimit = 4,
		starLevel = 5,
		passiveItem = 2,
		passiveExp = 50080,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[41] = {
		lv = 41,
		HeroExp = 4100,
		UpgradeMatNum = 9,
		ImproveMatNum = 30,
		DecomposeMatNum = 9,
		cardStar = 0,
		ImproveLimit = 4,
		starLevel = 5,
		passiveItem = 2,
		passiveExp = 53710,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[42] = {
		lv = 42,
		HeroExp = 4200,
		UpgradeMatNum = 9,
		ImproveMatNum = 30,
		DecomposeMatNum = 9,
		cardStar = 0,
		ImproveLimit = 4,
		starLevel = 5,
		passiveItem = 2,
		passiveExp = 57512,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[43] = {
		lv = 43,
		HeroExp = 4300,
		UpgradeMatNum = 9,
		ImproveMatNum = 30,
		DecomposeMatNum = 9,
		cardStar = 0,
		ImproveLimit = 4,
		starLevel = 5,
		passiveItem = 2,
		passiveExp = 61490,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[44] = {
		lv = 44,
		HeroExp = 4400,
		UpgradeMatNum = 9,
		ImproveMatNum = 30,
		DecomposeMatNum = 9,
		cardStar = 0,
		ImproveLimit = 4,
		starLevel = 5,
		passiveItem = 2,
		passiveExp = 65648,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[45] = {
		lv = 45,
		HeroExp = 4500,
		UpgradeMatNum = 10,
		ImproveMatNum = 37,
		DecomposeMatNum = 12,
		cardStar = 0,
		ImproveLimit = 5,
		starLevel = 6,
		passiveItem = 2,
		passiveExp = 69990,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[46] = {
		lv = 46,
		HeroExp = 4600,
		UpgradeMatNum = 10,
		ImproveMatNum = 37,
		DecomposeMatNum = 12,
		cardStar = 0,
		ImproveLimit = 5,
		starLevel = 6,
		passiveItem = 2,
		passiveExp = 74520,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[47] = {
		lv = 47,
		HeroExp = 4700,
		UpgradeMatNum = 10,
		ImproveMatNum = 37,
		DecomposeMatNum = 12,
		cardStar = 0,
		ImproveLimit = 5,
		starLevel = 6,
		passiveItem = 2,
		passiveExp = 79242,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[48] = {
		lv = 48,
		HeroExp = 4800,
		UpgradeMatNum = 10,
		ImproveMatNum = 37,
		DecomposeMatNum = 12,
		cardStar = 0,
		ImproveLimit = 5,
		starLevel = 6,
		passiveItem = 2,
		passiveExp = 84160,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[49] = {
		lv = 49,
		HeroExp = 4900,
		UpgradeMatNum = 10,
		ImproveMatNum = 37,
		DecomposeMatNum = 12,
		cardStar = 0,
		ImproveLimit = 5,
		starLevel = 6,
		passiveItem = 2,
		passiveExp = 89278,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[50] = {
		lv = 50,
		HeroExp = 5000,
		UpgradeMatNum = 12,
		ImproveMatNum = 45,
		DecomposeMatNum = 14,
		cardStar = 0,
		ImproveLimit = 5,
		starLevel = 6,
		passiveItem = 2,
		passiveExp = 94600,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[51] = {
		lv = 51,
		HeroExp = 5100,
		UpgradeMatNum = 12,
		ImproveMatNum = 45,
		DecomposeMatNum = 14,
		cardStar = 0,
		ImproveLimit = 5,
		starLevel = 7,
		passiveItem = 3,
		passiveExp = 100130,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[52] = {
		lv = 52,
		HeroExp = 5200,
		UpgradeMatNum = 12,
		ImproveMatNum = 45,
		DecomposeMatNum = 14,
		cardStar = 0,
		ImproveLimit = 5,
		starLevel = 7,
		passiveItem = 3,
		passiveExp = 105872,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[53] = {
		lv = 53,
		HeroExp = 5300,
		UpgradeMatNum = 12,
		ImproveMatNum = 45,
		DecomposeMatNum = 14,
		cardStar = 0,
		ImproveLimit = 5,
		starLevel = 7,
		passiveItem = 3,
		passiveExp = 111830,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[54] = {
		lv = 54,
		HeroExp = 5400,
		UpgradeMatNum = 12,
		ImproveMatNum = 45,
		DecomposeMatNum = 14,
		cardStar = 0,
		ImproveLimit = 5,
		starLevel = 7,
		passiveItem = 3,
		passiveExp = 118008,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[55] = {
		lv = 55,
		HeroExp = 5500,
		UpgradeMatNum = 14,
		ImproveMatNum = 55,
		DecomposeMatNum = 17,
		cardStar = 0,
		ImproveLimit = 5,
		starLevel = 7,
		passiveItem = 3,
		passiveExp = 124410,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[56] = {
		lv = 56,
		HeroExp = 5600,
		UpgradeMatNum = 14,
		ImproveMatNum = 55,
		DecomposeMatNum = 17,
		cardStar = 0,
		ImproveLimit = 5,
		starLevel = 8,
		passiveItem = 3,
		passiveExp = 131040,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[57] = {
		lv = 57,
		HeroExp = 5700,
		UpgradeMatNum = 14,
		ImproveMatNum = 55,
		DecomposeMatNum = 17,
		cardStar = 0,
		ImproveLimit = 5,
		starLevel = 8,
		passiveItem = 3,
		passiveExp = 137902,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[58] = {
		lv = 58,
		HeroExp = 5800,
		UpgradeMatNum = 14,
		ImproveMatNum = 55,
		DecomposeMatNum = 17,
		cardStar = 0,
		ImproveLimit = 5,
		starLevel = 8,
		passiveItem = 3,
		passiveExp = 145000,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[59] = {
		lv = 59,
		HeroExp = 5900,
		UpgradeMatNum = 14,
		ImproveMatNum = 55,
		DecomposeMatNum = 17,
		cardStar = 0,
		ImproveLimit = 5,
		starLevel = 8,
		passiveItem = 3,
		passiveExp = 152338,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[60] = {
		lv = 60,
		HeroExp = 6000,
		UpgradeMatNum = 16,
		ImproveMatNum = 66,
		DecomposeMatNum = 21,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 8,
		passiveItem = 3,
		passiveExp = 159920,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[61] = {
		lv = 61,
		HeroExp = 6100,
		UpgradeMatNum = 16,
		ImproveMatNum = 66,
		DecomposeMatNum = 21,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 9,
		passiveItem = 3,
		passiveExp = 167750,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[62] = {
		lv = 62,
		HeroExp = 6200,
		UpgradeMatNum = 16,
		ImproveMatNum = 66,
		DecomposeMatNum = 21,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 9,
		passiveItem = 3,
		passiveExp = 175832,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[63] = {
		lv = 63,
		HeroExp = 6300,
		UpgradeMatNum = 16,
		ImproveMatNum = 66,
		DecomposeMatNum = 21,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 9,
		passiveItem = 3,
		passiveExp = 184170,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[64] = {
		lv = 64,
		HeroExp = 6400,
		UpgradeMatNum = 16,
		ImproveMatNum = 66,
		DecomposeMatNum = 21,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 9,
		passiveItem = 3,
		passiveExp = 192768,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[65] = {
		lv = 65,
		HeroExp = 6500,
		UpgradeMatNum = 18,
		ImproveMatNum = 79,
		DecomposeMatNum = 25,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 9,
		passiveItem = 3,
		passiveExp = 201630,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[66] = {
		lv = 66,
		HeroExp = 6600,
		UpgradeMatNum = 18,
		ImproveMatNum = 79,
		DecomposeMatNum = 25,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 10,
		passiveItem = 3,
		passiveExp = 210760,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[67] = {
		lv = 67,
		HeroExp = 6700,
		UpgradeMatNum = 18,
		ImproveMatNum = 79,
		DecomposeMatNum = 25,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 10,
		passiveItem = 3,
		passiveExp = 220162,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[68] = {
		lv = 68,
		HeroExp = 6800,
		UpgradeMatNum = 18,
		ImproveMatNum = 79,
		DecomposeMatNum = 25,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 10,
		passiveItem = 3,
		passiveExp = 229840,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[69] = {
		lv = 69,
		HeroExp = 6900,
		UpgradeMatNum = 18,
		ImproveMatNum = 79,
		DecomposeMatNum = 25,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 10,
		passiveItem = 3,
		passiveExp = 239798,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[70] = {
		lv = 70,
		HeroExp = 7000,
		UpgradeMatNum = 20,
		ImproveMatNum = 93,
		DecomposeMatNum = 29,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 10,
		passiveItem = 3,
		passiveExp = 250040,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[71] = {
		lv = 71,
		HeroExp = 7100,
		UpgradeMatNum = 20,
		ImproveMatNum = 93,
		DecomposeMatNum = 29,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 11,
		passiveItem = 4,
		passiveExp = 260570,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[72] = {
		lv = 72,
		HeroExp = 7200,
		UpgradeMatNum = 20,
		ImproveMatNum = 93,
		DecomposeMatNum = 29,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 11,
		passiveItem = 4,
		passiveExp = 271392,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[73] = {
		lv = 73,
		HeroExp = 7300,
		UpgradeMatNum = 20,
		ImproveMatNum = 93,
		DecomposeMatNum = 29,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 11,
		passiveItem = 4,
		passiveExp = 282510,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[74] = {
		lv = 74,
		HeroExp = 7400,
		UpgradeMatNum = 20,
		ImproveMatNum = 93,
		DecomposeMatNum = 29,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 11,
		passiveItem = 4,
		passiveExp = 293928,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[75] = {
		lv = 75,
		HeroExp = 7500,
		UpgradeMatNum = 25,
		ImproveMatNum = 109,
		DecomposeMatNum = 34,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 11,
		passiveItem = 4,
		passiveExp = 305650,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[76] = {
		lv = 76,
		HeroExp = 7600,
		UpgradeMatNum = 25,
		ImproveMatNum = 109,
		DecomposeMatNum = 34,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 12,
		passiveItem = 4,
		passiveExp = 317680,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[77] = {
		lv = 77,
		HeroExp = 7700,
		UpgradeMatNum = 25,
		ImproveMatNum = 109,
		DecomposeMatNum = 34,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 12,
		passiveItem = 4,
		passiveExp = 330022,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[78] = {
		lv = 78,
		HeroExp = 7800,
		UpgradeMatNum = 25,
		ImproveMatNum = 109,
		DecomposeMatNum = 34,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 12,
		passiveItem = 4,
		passiveExp = 342680,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[79] = {
		lv = 79,
		HeroExp = 7900,
		UpgradeMatNum = 25,
		ImproveMatNum = 109,
		DecomposeMatNum = 34,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 12,
		passiveItem = 4,
		passiveExp = 355658,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[80] = {
		lv = 80,
		HeroExp = 8000,
		UpgradeMatNum = 30,
		ImproveMatNum = 129,
		DecomposeMatNum = 40,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 12,
		passiveItem = 4,
		passiveExp = 368960,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[81] = {
		lv = 81,
		HeroExp = 8100,
		UpgradeMatNum = 30,
		ImproveMatNum = 129,
		DecomposeMatNum = 40,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 13,
		passiveItem = 4,
		passiveExp = 382590,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[82] = {
		lv = 82,
		HeroExp = 8200,
		UpgradeMatNum = 30,
		ImproveMatNum = 129,
		DecomposeMatNum = 40,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 13,
		passiveItem = 4,
		passiveExp = 396552,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[83] = {
		lv = 83,
		HeroExp = 8300,
		UpgradeMatNum = 30,
		ImproveMatNum = 129,
		DecomposeMatNum = 40,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 13,
		passiveItem = 4,
		passiveExp = 410850,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[84] = {
		lv = 84,
		HeroExp = 8400,
		UpgradeMatNum = 30,
		ImproveMatNum = 129,
		DecomposeMatNum = 40,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 13,
		passiveItem = 4,
		passiveExp = 425488,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[85] = {
		lv = 85,
		HeroExp = 8500,
		UpgradeMatNum = 35,
		ImproveMatNum = 153,
		DecomposeMatNum = 48,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 13,
		passiveItem = 4,
		passiveExp = 440470,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[86] = {
		lv = 86,
		HeroExp = 8600,
		UpgradeMatNum = 35,
		ImproveMatNum = 153,
		DecomposeMatNum = 48,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 14,
		passiveItem = 4,
		passiveExp = 455800,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[87] = {
		lv = 87,
		HeroExp = 8700,
		UpgradeMatNum = 35,
		ImproveMatNum = 153,
		DecomposeMatNum = 48,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 14,
		passiveItem = 4,
		passiveExp = 471482,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[88] = {
		lv = 88,
		HeroExp = 8800,
		UpgradeMatNum = 35,
		ImproveMatNum = 153,
		DecomposeMatNum = 48,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 14,
		passiveItem = 4,
		passiveExp = 487520,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[89] = {
		lv = 89,
		HeroExp = 8900,
		UpgradeMatNum = 35,
		ImproveMatNum = 153,
		DecomposeMatNum = 48,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 14,
		passiveItem = 4,
		passiveExp = 503918,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[90] = {
		lv = 90,
		HeroExp = 9000,
		UpgradeMatNum = 40,
		ImproveMatNum = 181,
		DecomposeMatNum = 57,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 14,
		passiveItem = 4,
		passiveExp = 520680,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[91] = {
		lv = 91,
		HeroExp = 9100,
		UpgradeMatNum = 40,
		ImproveMatNum = 181,
		DecomposeMatNum = 57,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 15,
		passiveItem = 4,
		passiveExp = 537810,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[92] = {
		lv = 92,
		HeroExp = 9200,
		UpgradeMatNum = 40,
		ImproveMatNum = 181,
		DecomposeMatNum = 57,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 15,
		passiveItem = 4,
		passiveExp = 555312,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[93] = {
		lv = 93,
		HeroExp = 9300,
		UpgradeMatNum = 40,
		ImproveMatNum = 181,
		DecomposeMatNum = 57,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 15,
		passiveItem = 4,
		passiveExp = 573190,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[94] = {
		lv = 94,
		HeroExp = 9400,
		UpgradeMatNum = 40,
		ImproveMatNum = 181,
		DecomposeMatNum = 57,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 15,
		passiveItem = 4,
		passiveExp = 591448,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[95] = {
		lv = 95,
		HeroExp = 9500,
		UpgradeMatNum = 45,
		ImproveMatNum = 213,
		DecomposeMatNum = 67,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 15,
		passiveItem = 4,
		passiveExp = 610090,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[96] = {
		lv = 96,
		HeroExp = 9600,
		UpgradeMatNum = 45,
		ImproveMatNum = 213,
		DecomposeMatNum = 67,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 15,
		passiveItem = 4,
		passiveExp = 629120,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[97] = {
		lv = 97,
		HeroExp = 9700,
		UpgradeMatNum = 45,
		ImproveMatNum = 213,
		DecomposeMatNum = 67,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 15,
		passiveItem = 4,
		passiveExp = 648542,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[98] = {
		lv = 98,
		HeroExp = 9800,
		UpgradeMatNum = 45,
		ImproveMatNum = 213,
		DecomposeMatNum = 67,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 15,
		passiveItem = 4,
		passiveExp = 668360,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[99] = {
		lv = 99,
		HeroExp = 9900,
		UpgradeMatNum = 45,
		ImproveMatNum = 213,
		DecomposeMatNum = 67,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 15,
		passiveItem = 4,
		passiveExp = 688578,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[100] = {
		lv = 100,
		HeroExp = 10000,
		UpgradeMatNum = 0,
		ImproveMatNum = 249,
		DecomposeMatNum = 78,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 15,
		passiveItem = 4,
		passiveExp = 709200,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
	[101] = {
		lv = 101,
		HeroExp = 10100,
		UpgradeMatNum = 0,
		ImproveMatNum = 249,
		DecomposeMatNum = 78,
		cardStar = 0,
		ImproveLimit = 6,
		starLevel = 15,
		passiveItem = 4,
		passiveExp = 730230,
		compos1 = 0,
		compos2 = 0,
		compos5 = 0,
	},
}

return datas