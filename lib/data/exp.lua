local datas = {
	[1] = {
		lv = 1,
		HeroExp = 100,
		CardExp = 0,
		UpgradeMatNum = 1,
		ImproveMatNum = 1,
		DecomposeMatNum = 1,
		cardStar = 3,
		passiveGold = 300,
		ImproveLimit = 2,
	},
	[2] = {
		lv = 2,
		HeroExp = 300,
		CardExp = 100,
		UpgradeMatNum = 1,
		ImproveMatNum = 1,
		DecomposeMatNum = 1,
		cardStar = 4,
		passiveGold = 420,
		ImproveLimit = 2,
	},
	[3] = {
		lv = 3,
		HeroExp = 500,
		CardExp = 300,
		UpgradeMatNum = 1,
		ImproveMatNum = 1,
		DecomposeMatNum = 1,
		cardStar = 6,
		passiveGold = 580,
		ImproveLimit = 2,
	},
	[4] = {
		lv = 4,
		HeroExp = 700,
		CardExp = 500,
		UpgradeMatNum = 1,
		ImproveMatNum = 1,
		DecomposeMatNum = 1,
		cardStar = 8,
		passiveGold = 780,
		ImproveLimit = 2,
	},
	[5] = {
		lv = 5,
		HeroExp = 1000,
		CardExp = 700,
		UpgradeMatNum = 2,
		ImproveMatNum = 2,
		DecomposeMatNum = 1,
		cardStar = 10,
		passiveGold = 1020,
		ImproveLimit = 2,
	},
	[6] = {
		lv = 6,
		HeroExp = 1200,
		CardExp = 1000,
		UpgradeMatNum = 2,
		ImproveMatNum = 2,
		DecomposeMatNum = 1,
		cardStar = 13,
		passiveGold = 1300,
		ImproveLimit = 2,
	},
	[7] = {
		lv = 7,
		HeroExp = 1300,
		CardExp = 1200,
		UpgradeMatNum = 2,
		ImproveMatNum = 2,
		DecomposeMatNum = 1,
		cardStar = 16,
		passiveGold = 1620,
		ImproveLimit = 2,
	},
	[8] = {
		lv = 8,
		HeroExp = 1400,
		CardExp = 1300,
		UpgradeMatNum = 2,
		ImproveMatNum = 2,
		DecomposeMatNum = 1,
		cardStar = 20,
		passiveGold = 1980,
		ImproveLimit = 2,
	},
	[9] = {
		lv = 9,
		HeroExp = 1600,
		CardExp = 1400,
		UpgradeMatNum = 2,
		ImproveMatNum = 2,
		DecomposeMatNum = 1,
		cardStar = 24,
		passiveGold = 2380,
		ImproveLimit = 2,
	},
	[10] = {
		lv = 10,
		HeroExp = 1900,
		CardExp = 1600,
		UpgradeMatNum = 3,
		ImproveMatNum = 4,
		DecomposeMatNum = 1,
		cardStar = 28,
		passiveGold = 2820,
		ImproveLimit = 2,
	},
	[11] = {
		lv = 11,
		HeroExp = 2100,
		CardExp = 1900,
		UpgradeMatNum = 3,
		ImproveMatNum = 4,
		DecomposeMatNum = 1,
		cardStar = 33,
		passiveGold = 3300,
		ImproveLimit = 2,
	},
	[12] = {
		lv = 12,
		HeroExp = 2200,
		CardExp = 2100,
		UpgradeMatNum = 3,
		ImproveMatNum = 4,
		DecomposeMatNum = 1,
		cardStar = 38,
		passiveGold = 3820,
		ImproveLimit = 2,
	},
	[13] = {
		lv = 13,
		HeroExp = 2300,
		CardExp = 2200,
		UpgradeMatNum = 3,
		ImproveMatNum = 4,
		DecomposeMatNum = 1,
		cardStar = 44,
		passiveGold = 4380,
		ImproveLimit = 2,
	},
	[14] = {
		lv = 14,
		HeroExp = 2500,
		CardExp = 2300,
		UpgradeMatNum = 3,
		ImproveMatNum = 4,
		DecomposeMatNum = 1,
		cardStar = 50,
		passiveGold = 4980,
		ImproveLimit = 2,
	},
	[15] = {
		lv = 15,
		HeroExp = 2800,
		CardExp = 2500,
		UpgradeMatNum = 4,
		ImproveMatNum = 6,
		DecomposeMatNum = 2,
		cardStar = 56,
		passiveGold = 5620,
		ImproveLimit = 2,
	},
	[16] = {
		lv = 16,
		HeroExp = 3000,
		CardExp = 2800,
		UpgradeMatNum = 4,
		ImproveMatNum = 6,
		DecomposeMatNum = 2,
		cardStar = 0,
		passiveGold = 6300,
		ImproveLimit = 3,
	},
	[17] = {
		lv = 17,
		HeroExp = 3100,
		CardExp = 3000,
		UpgradeMatNum = 4,
		ImproveMatNum = 6,
		DecomposeMatNum = 2,
		cardStar = 0,
		passiveGold = 7020,
		ImproveLimit = 3,
	},
	[18] = {
		lv = 18,
		HeroExp = 3200,
		CardExp = 3100,
		UpgradeMatNum = 4,
		ImproveMatNum = 6,
		DecomposeMatNum = 2,
		cardStar = 0,
		passiveGold = 7780,
		ImproveLimit = 3,
	},
	[19] = {
		lv = 19,
		HeroExp = 3400,
		CardExp = 3200,
		UpgradeMatNum = 4,
		ImproveMatNum = 6,
		DecomposeMatNum = 2,
		cardStar = 0,
		passiveGold = 8580,
		ImproveLimit = 3,
	},
	[20] = {
		lv = 20,
		HeroExp = 3700,
		CardExp = 3400,
		UpgradeMatNum = 5,
		ImproveMatNum = 9,
		DecomposeMatNum = 3,
		cardStar = 0,
		passiveGold = 9420,
		ImproveLimit = 3,
	},
	[21] = {
		lv = 21,
		HeroExp = 3900,
		CardExp = 3700,
		UpgradeMatNum = 5,
		ImproveMatNum = 9,
		DecomposeMatNum = 3,
		cardStar = 0,
		passiveGold = 10300,
		ImproveLimit = 3,
	},
	[22] = {
		lv = 22,
		HeroExp = 4000,
		CardExp = 3900,
		UpgradeMatNum = 5,
		ImproveMatNum = 9,
		DecomposeMatNum = 3,
		cardStar = 0,
		passiveGold = 11220,
		ImproveLimit = 3,
	},
	[23] = {
		lv = 23,
		HeroExp = 4100,
		CardExp = 4000,
		UpgradeMatNum = 5,
		ImproveMatNum = 9,
		DecomposeMatNum = 3,
		cardStar = 0,
		passiveGold = 12180,
		ImproveLimit = 3,
	},
	[24] = {
		lv = 24,
		HeroExp = 4300,
		CardExp = 4100,
		UpgradeMatNum = 5,
		ImproveMatNum = 9,
		DecomposeMatNum = 3,
		cardStar = 0,
		passiveGold = 13180,
		ImproveLimit = 3,
	},
	[25] = {
		lv = 25,
		HeroExp = 4600,
		CardExp = 4300,
		UpgradeMatNum = 6,
		ImproveMatNum = 13,
		DecomposeMatNum = 4,
		cardStar = 0,
		passiveGold = 14220,
		ImproveLimit = 3,
	},
	[26] = {
		lv = 26,
		HeroExp = 4800,
		CardExp = 4600,
		UpgradeMatNum = 6,
		ImproveMatNum = 13,
		DecomposeMatNum = 4,
		cardStar = 0,
		passiveGold = 15300,
		ImproveLimit = 3,
	},
	[27] = {
		lv = 27,
		HeroExp = 4900,
		CardExp = 4800,
		UpgradeMatNum = 6,
		ImproveMatNum = 13,
		DecomposeMatNum = 4,
		cardStar = 0,
		passiveGold = 16420,
		ImproveLimit = 3,
	},
	[28] = {
		lv = 28,
		HeroExp = 5000,
		CardExp = 4900,
		UpgradeMatNum = 6,
		ImproveMatNum = 13,
		DecomposeMatNum = 4,
		cardStar = 0,
		passiveGold = 17580,
		ImproveLimit = 3,
	},
	[29] = {
		lv = 29,
		HeroExp = 5200,
		CardExp = 5000,
		UpgradeMatNum = 6,
		ImproveMatNum = 13,
		DecomposeMatNum = 4,
		cardStar = 0,
		passiveGold = 18780,
		ImproveLimit = 3,
	},
	[30] = {
		lv = 30,
		HeroExp = 5500,
		CardExp = 5200,
		UpgradeMatNum = 7,
		ImproveMatNum = 18,
		DecomposeMatNum = 6,
		cardStar = 0,
		passiveGold = 20020,
		ImproveLimit = 3,
	},
	[31] = {
		lv = 31,
		HeroExp = 5700,
		CardExp = 5500,
		UpgradeMatNum = 7,
		ImproveMatNum = 18,
		DecomposeMatNum = 6,
		cardStar = 0,
		passiveGold = 21300,
		ImproveLimit = 4,
	},
	[32] = {
		lv = 32,
		HeroExp = 5800,
		CardExp = 5700,
		UpgradeMatNum = 7,
		ImproveMatNum = 18,
		DecomposeMatNum = 6,
		cardStar = 0,
		passiveGold = 22620,
		ImproveLimit = 4,
	},
	[33] = {
		lv = 33,
		HeroExp = 5900,
		CardExp = 5800,
		UpgradeMatNum = 7,
		ImproveMatNum = 18,
		DecomposeMatNum = 6,
		cardStar = 0,
		passiveGold = 23980,
		ImproveLimit = 4,
	},
	[34] = {
		lv = 34,
		HeroExp = 6100,
		CardExp = 5900,
		UpgradeMatNum = 7,
		ImproveMatNum = 18,
		DecomposeMatNum = 6,
		cardStar = 0,
		passiveGold = 25380,
		ImproveLimit = 4,
	},
	[35] = {
		lv = 35,
		HeroExp = 6400,
		CardExp = 6100,
		UpgradeMatNum = 8,
		ImproveMatNum = 24,
		DecomposeMatNum = 7,
		cardStar = 0,
		passiveGold = 26820,
		ImproveLimit = 4,
	},
	[36] = {
		lv = 36,
		HeroExp = 6600,
		CardExp = 6400,
		UpgradeMatNum = 8,
		ImproveMatNum = 24,
		DecomposeMatNum = 7,
		cardStar = 0,
		passiveGold = 28300,
		ImproveLimit = 4,
	},
	[37] = {
		lv = 37,
		HeroExp = 6700,
		CardExp = 6600,
		UpgradeMatNum = 8,
		ImproveMatNum = 24,
		DecomposeMatNum = 7,
		cardStar = 0,
		passiveGold = 29820,
		ImproveLimit = 4,
	},
	[38] = {
		lv = 38,
		HeroExp = 6800,
		CardExp = 6700,
		UpgradeMatNum = 8,
		ImproveMatNum = 24,
		DecomposeMatNum = 7,
		cardStar = 0,
		passiveGold = 31380,
		ImproveLimit = 4,
	},
	[39] = {
		lv = 39,
		HeroExp = 7000,
		CardExp = 6800,
		UpgradeMatNum = 8,
		ImproveMatNum = 24,
		DecomposeMatNum = 7,
		cardStar = 0,
		passiveGold = 32980,
		ImproveLimit = 4,
	},
	[40] = {
		lv = 40,
		HeroExp = 7300,
		CardExp = 7000,
		UpgradeMatNum = 9,
		ImproveMatNum = 30,
		DecomposeMatNum = 9,
		cardStar = 0,
		passiveGold = 34620,
		ImproveLimit = 4,
	},
	[41] = {
		lv = 41,
		HeroExp = 7500,
		CardExp = 7300,
		UpgradeMatNum = 9,
		ImproveMatNum = 30,
		DecomposeMatNum = 9,
		cardStar = 0,
		passiveGold = 36300,
		ImproveLimit = 4,
	},
	[42] = {
		lv = 42,
		HeroExp = 7600,
		CardExp = 7500,
		UpgradeMatNum = 9,
		ImproveMatNum = 30,
		DecomposeMatNum = 9,
		cardStar = 0,
		passiveGold = 38020,
		ImproveLimit = 4,
	},
	[43] = {
		lv = 43,
		HeroExp = 7700,
		CardExp = 7600,
		UpgradeMatNum = 9,
		ImproveMatNum = 30,
		DecomposeMatNum = 9,
		cardStar = 0,
		passiveGold = 39780,
		ImproveLimit = 4,
	},
	[44] = {
		lv = 44,
		HeroExp = 7900,
		CardExp = 7700,
		UpgradeMatNum = 9,
		ImproveMatNum = 30,
		DecomposeMatNum = 9,
		cardStar = 0,
		passiveGold = 41580,
		ImproveLimit = 4,
	},
	[45] = {
		lv = 45,
		HeroExp = 8200,
		CardExp = 7900,
		UpgradeMatNum = 10,
		ImproveMatNum = 37,
		DecomposeMatNum = 12,
		cardStar = 0,
		passiveGold = 43420,
		ImproveLimit = 4,
	},
	[46] = {
		lv = 46,
		HeroExp = 8400,
		CardExp = 8200,
		UpgradeMatNum = 10,
		ImproveMatNum = 37,
		DecomposeMatNum = 12,
		cardStar = 0,
		passiveGold = 45300,
		ImproveLimit = 5,
	},
	[47] = {
		lv = 47,
		HeroExp = 8500,
		CardExp = 8400,
		UpgradeMatNum = 10,
		ImproveMatNum = 37,
		DecomposeMatNum = 12,
		cardStar = 0,
		passiveGold = 47220,
		ImproveLimit = 5,
	},
	[48] = {
		lv = 48,
		HeroExp = 8600,
		CardExp = 8500,
		UpgradeMatNum = 10,
		ImproveMatNum = 37,
		DecomposeMatNum = 12,
		cardStar = 0,
		passiveGold = 49180,
		ImproveLimit = 5,
	},
	[49] = {
		lv = 49,
		HeroExp = 8800,
		CardExp = 8600,
		UpgradeMatNum = 10,
		ImproveMatNum = 37,
		DecomposeMatNum = 12,
		cardStar = 0,
		passiveGold = 51180,
		ImproveLimit = 5,
	},
	[50] = {
		lv = 50,
		HeroExp = 9100,
		CardExp = 8800,
		UpgradeMatNum = 12,
		ImproveMatNum = 45,
		DecomposeMatNum = 14,
		cardStar = 0,
		passiveGold = 53220,
		ImproveLimit = 5,
	},
	[51] = {
		lv = 51,
		HeroExp = 10000,
		CardExp = 9100,
		UpgradeMatNum = 12,
		ImproveMatNum = 45,
		DecomposeMatNum = 14,
		cardStar = 0,
		passiveGold = 55300,
		ImproveLimit = 5,
	},
	[52] = {
		lv = 52,
		HeroExp = 11000,
		CardExp = 10000,
		UpgradeMatNum = 12,
		ImproveMatNum = 45,
		DecomposeMatNum = 14,
		cardStar = 0,
		passiveGold = 57420,
		ImproveLimit = 5,
	},
	[53] = {
		lv = 53,
		HeroExp = 12000,
		CardExp = 11000,
		UpgradeMatNum = 12,
		ImproveMatNum = 45,
		DecomposeMatNum = 14,
		cardStar = 0,
		passiveGold = 59580,
		ImproveLimit = 5,
	},
	[54] = {
		lv = 54,
		HeroExp = 13000,
		CardExp = 12000,
		UpgradeMatNum = 12,
		ImproveMatNum = 45,
		DecomposeMatNum = 14,
		cardStar = 0,
		passiveGold = 61780,
		ImproveLimit = 5,
	},
	[55] = {
		lv = 55,
		HeroExp = 14000,
		CardExp = 13000,
		UpgradeMatNum = 14,
		ImproveMatNum = 55,
		DecomposeMatNum = 17,
		cardStar = 0,
		passiveGold = 64020,
		ImproveLimit = 5,
	},
	[56] = {
		lv = 56,
		HeroExp = 15000,
		CardExp = 14000,
		UpgradeMatNum = 14,
		ImproveMatNum = 55,
		DecomposeMatNum = 17,
		cardStar = 0,
		passiveGold = 66300,
		ImproveLimit = 5,
	},
	[57] = {
		lv = 57,
		HeroExp = 16000,
		CardExp = 15000,
		UpgradeMatNum = 14,
		ImproveMatNum = 55,
		DecomposeMatNum = 17,
		cardStar = 0,
		passiveGold = 68620,
		ImproveLimit = 5,
	},
	[58] = {
		lv = 58,
		HeroExp = 17000,
		CardExp = 16000,
		UpgradeMatNum = 14,
		ImproveMatNum = 55,
		DecomposeMatNum = 17,
		cardStar = 0,
		passiveGold = 70980,
		ImproveLimit = 5,
	},
	[59] = {
		lv = 59,
		HeroExp = 18000,
		CardExp = 17000,
		UpgradeMatNum = 14,
		ImproveMatNum = 55,
		DecomposeMatNum = 17,
		cardStar = 0,
		passiveGold = 73380,
		ImproveLimit = 5,
	},
	[60] = {
		lv = 60,
		HeroExp = 19000,
		CardExp = 18000,
		UpgradeMatNum = 16,
		ImproveMatNum = 66,
		DecomposeMatNum = 21,
		cardStar = 0,
		passiveGold = 75820,
		ImproveLimit = 5,
	},
	[61] = {
		lv = 61,
		HeroExp = 20000,
		CardExp = 19000,
		UpgradeMatNum = 16,
		ImproveMatNum = 66,
		DecomposeMatNum = 21,
		cardStar = 0,
		passiveGold = 78300,
		ImproveLimit = 6,
	},
	[62] = {
		lv = 62,
		HeroExp = 21000,
		CardExp = 20000,
		UpgradeMatNum = 16,
		ImproveMatNum = 66,
		DecomposeMatNum = 21,
		cardStar = 0,
		passiveGold = 80820,
		ImproveLimit = 6,
	},
	[63] = {
		lv = 63,
		HeroExp = 22000,
		CardExp = 21000,
		UpgradeMatNum = 16,
		ImproveMatNum = 66,
		DecomposeMatNum = 21,
		cardStar = 0,
		passiveGold = 83380,
		ImproveLimit = 6,
	},
	[64] = {
		lv = 64,
		HeroExp = 23000,
		CardExp = 22000,
		UpgradeMatNum = 16,
		ImproveMatNum = 66,
		DecomposeMatNum = 21,
		cardStar = 0,
		passiveGold = 85980,
		ImproveLimit = 6,
	},
	[65] = {
		lv = 65,
		HeroExp = 24000,
		CardExp = 23000,
		UpgradeMatNum = 18,
		ImproveMatNum = 79,
		DecomposeMatNum = 25,
		cardStar = 0,
		passiveGold = 88620,
		ImproveLimit = 6,
	},
	[66] = {
		lv = 66,
		HeroExp = 25000,
		CardExp = 24000,
		UpgradeMatNum = 18,
		ImproveMatNum = 79,
		DecomposeMatNum = 25,
		cardStar = 0,
		passiveGold = 91300,
		ImproveLimit = 6,
	},
	[67] = {
		lv = 67,
		HeroExp = 26000,
		CardExp = 25000,
		UpgradeMatNum = 18,
		ImproveMatNum = 79,
		DecomposeMatNum = 25,
		cardStar = 0,
		passiveGold = 94020,
		ImproveLimit = 6,
	},
	[68] = {
		lv = 68,
		HeroExp = 27000,
		CardExp = 26000,
		UpgradeMatNum = 18,
		ImproveMatNum = 79,
		DecomposeMatNum = 25,
		cardStar = 0,
		passiveGold = 96780,
		ImproveLimit = 6,
	},
	[69] = {
		lv = 69,
		HeroExp = 28000,
		CardExp = 27000,
		UpgradeMatNum = 18,
		ImproveMatNum = 79,
		DecomposeMatNum = 25,
		cardStar = 0,
		passiveGold = 99580,
		ImproveLimit = 6,
	},
	[70] = {
		lv = 70,
		HeroExp = 29000,
		CardExp = 28000,
		UpgradeMatNum = 20,
		ImproveMatNum = 93,
		DecomposeMatNum = 29,
		cardStar = 0,
		passiveGold = 102420,
		ImproveLimit = 6,
	},
	[71] = {
		lv = 71,
		HeroExp = 30000,
		CardExp = 29000,
		UpgradeMatNum = 20,
		ImproveMatNum = 93,
		DecomposeMatNum = 29,
		cardStar = 0,
		passiveGold = 105300,
		ImproveLimit = 6,
	},
	[72] = {
		lv = 72,
		HeroExp = 31000,
		CardExp = 30000,
		UpgradeMatNum = 20,
		ImproveMatNum = 93,
		DecomposeMatNum = 29,
		cardStar = 0,
		passiveGold = 108220,
		ImproveLimit = 6,
	},
	[73] = {
		lv = 73,
		HeroExp = 32000,
		CardExp = 31000,
		UpgradeMatNum = 20,
		ImproveMatNum = 93,
		DecomposeMatNum = 29,
		cardStar = 0,
		passiveGold = 111180,
		ImproveLimit = 6,
	},
	[74] = {
		lv = 74,
		HeroExp = 33000,
		CardExp = 32000,
		UpgradeMatNum = 20,
		ImproveMatNum = 93,
		DecomposeMatNum = 29,
		cardStar = 0,
		passiveGold = 114180,
		ImproveLimit = 6,
	},
	[75] = {
		lv = 75,
		HeroExp = 34000,
		CardExp = 33000,
		UpgradeMatNum = 25,
		ImproveMatNum = 109,
		DecomposeMatNum = 34,
		cardStar = 0,
		passiveGold = 117220,
		ImproveLimit = 6,
	},
	[76] = {
		lv = 76,
		HeroExp = 35000,
		CardExp = 34000,
		UpgradeMatNum = 25,
		ImproveMatNum = 109,
		DecomposeMatNum = 34,
		cardStar = 0,
		passiveGold = 120300,
		ImproveLimit = 6,
	},
	[77] = {
		lv = 77,
		HeroExp = 36000,
		CardExp = 35000,
		UpgradeMatNum = 25,
		ImproveMatNum = 109,
		DecomposeMatNum = 34,
		cardStar = 0,
		passiveGold = 123420,
		ImproveLimit = 6,
	},
	[78] = {
		lv = 78,
		HeroExp = 37000,
		CardExp = 36000,
		UpgradeMatNum = 25,
		ImproveMatNum = 109,
		DecomposeMatNum = 34,
		cardStar = 0,
		passiveGold = 126580,
		ImproveLimit = 6,
	},
	[79] = {
		lv = 79,
		HeroExp = 38000,
		CardExp = 37000,
		UpgradeMatNum = 25,
		ImproveMatNum = 109,
		DecomposeMatNum = 34,
		cardStar = 0,
		passiveGold = 129780,
		ImproveLimit = 6,
	},
	[80] = {
		lv = 80,
		HeroExp = 39000,
		CardExp = 38000,
		UpgradeMatNum = 30,
		ImproveMatNum = 129,
		DecomposeMatNum = 40,
		cardStar = 0,
		passiveGold = 133020,
		ImproveLimit = 6,
	},
	[81] = {
		lv = 81,
		HeroExp = 40000,
		CardExp = 39000,
		UpgradeMatNum = 30,
		ImproveMatNum = 129,
		DecomposeMatNum = 40,
		cardStar = 0,
		passiveGold = 136300,
		ImproveLimit = 6,
	},
	[82] = {
		lv = 82,
		HeroExp = 41000,
		CardExp = 40000,
		UpgradeMatNum = 30,
		ImproveMatNum = 129,
		DecomposeMatNum = 40,
		cardStar = 0,
		passiveGold = 139620,
		ImproveLimit = 6,
	},
	[83] = {
		lv = 83,
		HeroExp = 42000,
		CardExp = 41000,
		UpgradeMatNum = 30,
		ImproveMatNum = 129,
		DecomposeMatNum = 40,
		cardStar = 0,
		passiveGold = 142980,
		ImproveLimit = 6,
	},
	[84] = {
		lv = 84,
		HeroExp = 43000,
		CardExp = 42000,
		UpgradeMatNum = 30,
		ImproveMatNum = 129,
		DecomposeMatNum = 40,
		cardStar = 0,
		passiveGold = 146380,
		ImproveLimit = 6,
	},
	[85] = {
		lv = 85,
		HeroExp = 44000,
		CardExp = 43000,
		UpgradeMatNum = 35,
		ImproveMatNum = 153,
		DecomposeMatNum = 48,
		cardStar = 0,
		passiveGold = 149820,
		ImproveLimit = 6,
	},
	[86] = {
		lv = 86,
		HeroExp = 45000,
		CardExp = 44000,
		UpgradeMatNum = 35,
		ImproveMatNum = 153,
		DecomposeMatNum = 48,
		cardStar = 0,
		passiveGold = 153300,
		ImproveLimit = 6,
	},
	[87] = {
		lv = 87,
		HeroExp = 46000,
		CardExp = 45000,
		UpgradeMatNum = 35,
		ImproveMatNum = 153,
		DecomposeMatNum = 48,
		cardStar = 0,
		passiveGold = 156820,
		ImproveLimit = 6,
	},
	[88] = {
		lv = 88,
		HeroExp = 47000,
		CardExp = 46000,
		UpgradeMatNum = 35,
		ImproveMatNum = 153,
		DecomposeMatNum = 48,
		cardStar = 0,
		passiveGold = 160380,
		ImproveLimit = 6,
	},
	[89] = {
		lv = 89,
		HeroExp = 48000,
		CardExp = 47000,
		UpgradeMatNum = 35,
		ImproveMatNum = 153,
		DecomposeMatNum = 48,
		cardStar = 0,
		passiveGold = 163980,
		ImproveLimit = 6,
	},
	[90] = {
		lv = 90,
		HeroExp = 49000,
		CardExp = 48000,
		UpgradeMatNum = 40,
		ImproveMatNum = 181,
		DecomposeMatNum = 57,
		cardStar = 0,
		passiveGold = 167620,
		ImproveLimit = 6,
	},
	[91] = {
		lv = 91,
		HeroExp = 50000,
		CardExp = 49000,
		UpgradeMatNum = 40,
		ImproveMatNum = 181,
		DecomposeMatNum = 57,
		cardStar = 0,
		passiveGold = 171300,
		ImproveLimit = 6,
	},
	[92] = {
		lv = 92,
		HeroExp = 51000,
		CardExp = 50000,
		UpgradeMatNum = 40,
		ImproveMatNum = 181,
		DecomposeMatNum = 57,
		cardStar = 0,
		passiveGold = 175020,
		ImproveLimit = 6,
	},
	[93] = {
		lv = 93,
		HeroExp = 52000,
		CardExp = 51000,
		UpgradeMatNum = 40,
		ImproveMatNum = 181,
		DecomposeMatNum = 57,
		cardStar = 0,
		passiveGold = 178780,
		ImproveLimit = 6,
	},
	[94] = {
		lv = 94,
		HeroExp = 53000,
		CardExp = 52000,
		UpgradeMatNum = 40,
		ImproveMatNum = 181,
		DecomposeMatNum = 57,
		cardStar = 0,
		passiveGold = 182580,
		ImproveLimit = 6,
	},
	[95] = {
		lv = 95,
		HeroExp = 54000,
		CardExp = 53000,
		UpgradeMatNum = 45,
		ImproveMatNum = 213,
		DecomposeMatNum = 67,
		cardStar = 0,
		passiveGold = 186420,
		ImproveLimit = 6,
	},
	[96] = {
		lv = 96,
		HeroExp = 55000,
		CardExp = 54000,
		UpgradeMatNum = 45,
		ImproveMatNum = 213,
		DecomposeMatNum = 67,
		cardStar = 0,
		passiveGold = 190300,
		ImproveLimit = 6,
	},
	[97] = {
		lv = 97,
		HeroExp = 56000,
		CardExp = 55000,
		UpgradeMatNum = 45,
		ImproveMatNum = 213,
		DecomposeMatNum = 67,
		cardStar = 0,
		passiveGold = 194220,
		ImproveLimit = 6,
	},
	[98] = {
		lv = 98,
		HeroExp = 57000,
		CardExp = 56000,
		UpgradeMatNum = 45,
		ImproveMatNum = 213,
		DecomposeMatNum = 67,
		cardStar = 0,
		passiveGold = 198180,
		ImproveLimit = 6,
	},
	[99] = {
		lv = 99,
		HeroExp = 58000,
		CardExp = 57000,
		UpgradeMatNum = 45,
		ImproveMatNum = 213,
		DecomposeMatNum = 67,
		cardStar = 0,
		passiveGold = 202180,
		ImproveLimit = 6,
	},
	[100] = {
		lv = 100,
		HeroExp = 59000,
		CardExp = 58000,
		UpgradeMatNum = 0,
		ImproveMatNum = 249,
		DecomposeMatNum = 78,
		cardStar = 0,
		passiveGold = 206220,
		ImproveLimit = 6,
	},
	[101] = {
		lv = 101,
		HeroExp = 60000,
		CardExp = 59000,
		UpgradeMatNum = 0,
		ImproveMatNum = 249,
		DecomposeMatNum = 78,
		cardStar = 0,
		passiveGold = 210300,
		ImproveLimit = 6,
	},
}

return datas