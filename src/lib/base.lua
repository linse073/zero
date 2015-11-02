
local Director = cc.Director:getInstance()
local Scheduler = Director:getScheduler()

local Base = {}

Base.Debug = false

Base.RANDNUM_1	=	41
Base.RANDNUM_2	=	18
Base.RANDNUM_3	=	57
Base.RANDNUM_4	=	49
Base.RANDNUM_5	=	94
Base.RANDNUM_6	=	66
Base.RANDNUM_7	=	70
Base.RANDNUM_8	=	1
Base.RANDNUM_9	=	69
Base.RANDNUM_10	=	39
Base.RANDNUM_11	=	17
Base.RANDNUM_12	=	42
Base.RANDNUM_13	=	12
Base.RANDNUM_14	=	89
Base.RANDNUM_15	=	54
Base.RANDNUM_16	=	65
Base.RANDNUM_17	=	81
Base.RANDNUM_18	=	16
Base.RANDNUM_19	=	63
Base.RANDNUM_20	=	71
Base.RANDNUM_21	=	86
Base.RANDNUM_22	=	6
Base.RANDNUM_23	=	27
Base.RANDNUM_24	=	34
Base.RANDNUM_25	=	3
Base.RANDNUM_26	=	20
Base.RANDNUM_27	=	35
Base.RANDNUM_28	=	15
Base.RANDNUM_29	=	44
Base.RANDNUM_30	=	46
Base.RANDNUM_31	=	33
Base.RANDNUM_32	=	30
Base.RANDNUM_33	=	74
Base.RANDNUM_34	=	88
Base.RANDNUM_35 =   2
Base.RANDNUM_36 =   5
Base.RANDNUM_37 =   4
Base.RANDNUM_38 =   101
Base.RANDNUM_39 =   102
Base.RANDNUM_40 =   103
Base.RANDNUM_41 =   104
Base.RANDNUM_42  =   23
Base.RANDNUM_43  =   32
Base.RANDNUM_44  =   51
Base.RANDNUM_45	=	52
Base.RANDNUM_46	=	53
Base.RANDNUM_47	=	55
Base.RANDNUM_48	=	56
Base.RANDNUM_49	=	58
Base.RANDNUM_50	=	59
Base.RANDNUM_51	=	60
Base.RANDNUM_52	=	61
Base.RANDNUM_53	=	62
Base.RANDNUM_54	=	90

Base.SSI_CL = 0		-- 客户端
Base.SSI_AS = 1		-- 账号服务器
Base.SSI_LS = 2		-- 登陆服务器
Base.SSI_WS = 3		-- 大区服务器
Base.SSI_ZS = 4		-- 城镇服务器
Base.SSI_JS = 5		-- 验证服务器
Base.SSI_DS = 6		-- 数据库日志服务器
Base.SSI_BS = 7		-- 数据库服务器
Base.SSI_GS = 9		-- 全局服务器
Base.SSI_GM = 10	-- GM

-- Base.CARD_STAR_LV = {[10]=1, [30]=2, [80]=3, [180]=4, [360]=5, [660]=6};
Base.CARD_STAR_LV = {10, 30, 80, 180, 360, 660}

Base.ITEM_COLOR_QUALITY = {
	{r=255, g=255, b=255, a=255},
	{r=111, g=233, b=18, a=255},
	{r=70, g=222, b=255, a=255},
	{r=20, g=47, b=126, a=255},
	{r=191, g=30, b=160, a=255},
	{r=240, g=255, b=0, a=255},
	{r=241, g=132, b=38, a=255},
	{r=226, g=0, b=23, a=255},
	{r=254, g=138, b=134, a=255},
}
-- #define MAKE_FOURCC(a,b,c,d)  ( ((uint32_t)d) | ( ((uint32_t)c) << 8 ) | ( ((uint32_t)b) << 16 ) | ( ((uint32_t)a) << 24 ) )
-- function Base.MAKE_FOURCC(a, b, c, d)
--     local fourcc = bit.bor(string.byte(a), bit.blshift(string.byte(b), 8))
--     fourcc = bit.bor(fourcc, bit.blshift(string.byte(c), 16))
--     return bit.bor(fourcc, bit.blshift(string.byte(d), 24))
-- end

-- Base.SSD_MMOBILE_MAGIC		    = Base.MAKE_FOURCC('M', 'M', 'B', 'L')
-- Base.SSD_SEND_SIZE			    = 64*1024
-- Base.SSD_TOURIST_UID_LEN		= 64
-- Base.SSD_MAX_ACCOUNT			= 56
-- Base.SSD_MAX_PASSWORD		    = 32
-- Base.SSD_IP_LEN				    = 16
-- Base.SSD_SERIAL_NUM			    = 20
-- Base.SSD_AT_LEN				    = 36
-- Base.SSD_OPENID_LEN			    = 36
-- Base.SSD_APP_SERIAL_LEN		    = 18
-- Base.SSD_PHONE_LEN			    = 12
-- Base.SSD_ENDSTR_LEN			    = 1
-- Base.SSD_MAX_CHAR_NAME		    = 20
-- Base.SSD_MAX_ITEM_NAME		    = 32
-- Base.SSD_MAX_CARD_NUM		    = 200 + 1		-- +1多一张主角卡固定在0的位置
-- Base.SSD_MAX_CAMP_NUM		    = 5
-- Base.SSD_MAX_INVALID_CARDIDX	= 999			-- 无效卡牌槽
-- Base.SSD_MAX_ITEM_NUM		    = 200			-- 最多道具数量

--#define MAKE_VERSION(MAIN,SUB1,SUB2,SUB3) ((MAIN << 24)| (SUB1 << 16) | (SUB2 << 8) | SUB3)
function Base.MAKE_VERSION(main, sub1, sub2, sub3)
    local version = bit.bor(bit.blshift(main, 24), bit.blshift(sub1, 16))
    version = bit.bor(version, bit.blshift(sub2, 8))
    return bit.bor(version, sub3)
end

--#define CMD_DEF(form,to,cmd)	((form<<12) | (to<<8) | cmd)
function Base.CMD_DEF(from, to, cmd)
    local command = bit.bor(bit.blshift(from, 12), bit.blshift(to, 8))
    return bit.bor(command, cmd)
end

--随机
--没有参数时返回0~1的浮点随机
--1个参数m时产生1~m的整型随机
--2个参数m,n时产生m~n的整型随机
function Base.Random(m, n)
    if m and n then
    	m = m * 10000
        n = n * 10000
        return (math.random(m, n) / 10000)
    elseif m then
        return (math.random(10000, m * 10000) / 10000)
    end
    return math.random()
end

-- 范围随机
function Base.rangeRandom(t, s, f1, f2)
    local l = #t
    for i = 1, s do
        local n = math.random(i, l)
        t[i], t[n] = t[n], t[i]
    end
    if f1 then
        for i = 1, s do
            f1(t[i])
        end
    end
    if f2 then
        for i = s+1, l do
            f2(t[i])
        end
    end
end

Base.VERSION_NUM = Base.MAKE_VERSION(0, 0, 1, 2)
Base.VERSION_STR = "0.0.1.2"

local utils = require("framework.cc.utils.init")
local ByteArray = utils.ByteArray
Base.ENDIAN = ByteArray.ENDIAN_LITTLE

Base.JOB_STRING = {"warrior", "assassin", "gunner", "wizard"}
Base.ITEM_NEED_JOB_STRING = {"剑士", "刺客", "枪手", "巫师", "近战", "远程", "通用"}
Base.ITEM_QUALITY_NAME = {"劣质", "普通", "精良", "稀有", "卓越", "完美", "传说", "至尊", "神"}

-- 取整
function Base.IntDiv(a, b)
	local x = math.floor(a / b)
	return x
end

-- 秒转时间,精确到秒
function Base.SecondToTime(second)
	local hour = math.floor(second / 3600)
	local rest = second % 3600
	local minite = math.floor(rest / 60)
	local second = rest % 60

	return hour, minite, second
end

-- 将字符串转换为带换行的字符串，num为单行的文字数
function Base.StrToLineStr(str, num)
	assert(type(str) == "string")
	local start = 1
	local tail = length
	local outStr = ""
	
	local i = 1
	while start < string.len(str) do
		local slimStr
		local slimNum
		slimStr,slimNum = Base.SubUTF8String(str, start, slimNum)
		outStr = outStr .. slimStr
		if math.mod(i,num) == 0 then
			outStr = outStr .. "\n"
		end
		start = start + slimNum
		i = i + 1
	end

	return outStr
end

-- 截取utf8字符串,s:字符串,n:截取位置,slimNum:截取字节个数
function Base.SubUTF8String(s, n, slimNum)	  
	local dropping = string.byte(s, n)    
	if not dropping then 
		return s
	end    
	
	if dropping > 0xfc then
		slimNum = 6
	elseif dropping > 0xf8 then
		slimNum = 5
    elseif dropping > 0xf0 then
        slimNum = 4
    elseif dropping > 0xe0 then
        slimNum = 3
    elseif dropping > 0xc0 then
        slimNum = 2
    else
        slimNum = 1
    end
	
	local str = string.char(dropping)
	for i=1,slimNum-1 do
		local charCode = string.byte(s, n+i)
		str = str..string.char(charCode)
	end
	
	return str,slimNum
end 

--- 获取utf8编码字符串正确长度的方法
-- @param str
-- @return number
function Base.UtfStrLen(str)
	local len = #str
	local left = len
	local num = 0
	local arr={0,0xc0,0xe0,0xf0,0xf8,0xfc}
	while left ~= 0 do
		local tmp=string.byte(str,-left)
		local i=#arr
		while arr[i] do
			if tmp>=arr[i] then left=left-i break end
			i=i-1
		end
		num=num+1
	end
	return num
end

--将整数拆分成单个个位数
function Base.NumberAnalysis(num)
	-- num = math.floor(math.abs(num))
	-- local num_len = string.len(num)
	-- local numTable = {}
	-- for i = 1, num_len do
        -- numTable[i] = math.floor((num%10^i) / 10^(i-1))
    -- end
	-- return numTable

    local s = tostring(math.floor(math.abs(num)))
    local len = #s
    local t = {}
    for i = 1, #s do
        local index = len - i + 1
        t[i] = tonumber(string.sub(s, index, index))
    end
    return t
end

-- 贝塞尔曲线,p0起点,p1控制点,p2终点
function Base.Bezier(p0, p1, p2, t, minSpeed)
	local resultPos = {x=0, y=0}
	if t < 0.5 then
		t = (2 * (minSpeed - 1) * t * t + 2 * t) / (minSpeed + 1)
	else
		t = 0.5 + (2 * (1 - minSpeed) * t + 3 * minSpeed - 1) * (t - 0.5) / (minSpeed + 1)
	end
	
	if t >= 1 then
		resultPos.x = p2.x;
		resultPos.y = p2.y;
	else
		resultPos.x = p0.x + t * (2 * (1 - t) * (p1.x - p0.x) + t * (p2.x - p0.x))
		resultPos.y = p0.y + t * (2 * (1 - t) * (p1.y - p0.y) + t * (p2.y - p0.y))
	end
	
	return resultPos
end

-- 枚举
function Base.CreatEnum(enum) 
    local enumtbl = {} 
    local enumindex = -1 
    for i, v in ipairs(enum) do 
        enumtbl[v] = enumindex + i 
    end 
    return enumtbl 
end

function Base.darkNode(node,isAllChild)
	local vertDefaultSource = "\n"..
    "attribute vec4 a_position; \n" ..
    "attribute vec2 a_texCoord; \n" ..
    "attribute vec4 a_color; \n"..                                                    
    "#ifdef GL_ES  \n"..
    "varying lowp vec4 v_fragmentColor;\n"..
    "varying mediump vec2 v_texCoord;\n"..
    "#else                      \n" ..
    "varying vec4 v_fragmentColor; \n" ..
    "varying vec2 v_texCoord;  \n"..
    "#endif    \n"..
    "void main() \n"..
    "{\n" ..
    "gl_Position = CC_PMatrix * a_position; \n"..
    "v_fragmentColor = a_color;\n"..
    "v_texCoord = a_texCoord;\n"..
    "}"
     
    local pszFragSource = "#ifdef GL_ES \n" ..
    "precision mediump float; \n" ..
    "#endif \n" ..
    "varying vec4 v_fragmentColor; \n" ..
    "varying vec2 v_texCoord; \n" ..
    "void main(void) \n" ..
    "{ \n" ..
    "vec4 c = texture2D(CC_Texture0, v_texCoord); \n" ..
    "gl_FragColor.xyz = vec3(0.4*c.r + 0.3*c.g +0.3*c.b); \n"..
    "gl_FragColor.w = c.w; \n"..
    "}"
 
    local pProgram = cc.GLProgram:createWithByteArrays(vertDefaultSource,pszFragSource)
     
    pProgram:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    pProgram:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    pProgram:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    pProgram:link()
    pProgram:updateUniforms()
    node:setGLProgram(pProgram)
	
	if isAllChild then
		local children = node:getChildren()
		if children and table.nums(children) > 0 then
			for i,v in ipairs(children) do
				Base.darkNode(v,isAllChild)
			end
		end
	end
end

function Base.darkRecover(node)
	node:setGLProgramState(cc.GLProgramState:getOrCreateWithGLProgram(cc.GLProgramCache:getInstance():getGLProgram("ShaderPositionTextureColor_noMVP")))
	local children = node:getChildren()
	if children and table.nums(children) > 0 then
		for i,v in ipairs(children) do
			Base.darkRecover(v)
		end
	end
end

function Base.SetButtonEnabled(button,enabled)
	if button then
		button:setBright(enabled)
		button:setEnabled(enabled)
	end
end

function Base.IsTableEmpty(tab)
	if not tab then
		return true
	end
	
	for i,v in pairs(tab) do
		return false
	end
	
	return true
end

function Base.delayCallOnce(func, time)
    local handle
    handle = Scheduler:scheduleScriptFunc(function()
        Scheduler:unscheduleScriptEntry(handle)
        func()
    end, time, false)
end

function Base.pushScene(scene, ...)
    local nextScene = Director:getNextScene()
    if not nextScene or not nextScene.class or nextScene.class.__cname ~= scene then
        local scene = require("app.scenes." .. scene).new(...)
        Director:pushScene(scene)
    end
end

Base.jumpH = 200
Base.gravity = -10
Base.jump = 20
Base.move = 5
Base.climb = 5

-- task type
Base.TASK_TYPE_MASTER = 1
Base.TASK_TYPE_DAY = 2
Base.TASK_TYPE_ACHIEVEMENT = 3

Base.TASK_STATUS_UNDONE = 0
Base.TASK_STATUS_DONE = 1
Base.TASK_STATUS_FINISH = 2
Base.TASK_STATUS_NOT_ACCEPT = 3

Base.ROLE_TYPE_PLAYER = 0
Base.ROLE_TYPE_MONSTER = 1
Base.ROLE_TYPE_NPC = 2

Base.ECT_NONE = 0
Base.ECT_TALK = 1					-- 对话
Base.ECT_KILL = 2					-- 杀指定怪
Base.ECT_STAGE_COMPLETED = 3		-- 完成特定关卡
Base.ECT_STAGE_CLEAN = 4			-- 扫荡特点关卡
Base.ECT_CHAPTER_COMPLETED = 5		-- 特点章节完成
Base.ECT_OPEN_CASE = 6				-- 开宝箱
Base.ECT_SKILL_LVUP = 7				-- 技能升级
Base.ECT_SKILL_UPGRADE = 8			-- 技能进阶
Base.ECT_SKILL_MIX = 9				-- 技能融合
Base.ECT_EQUIP_STRENTH = 10			-- 装备强化
Base.ECT_EQUIP_LVUP = 11			-- 装备升级
Base.ECT_EQUIP_UPGRADE = 12			-- 装备进阶
Base.ECT_ADD_STONE = 13				-- 宝石镶嵌
Base.ECT_OFF_STONE = 14				-- 宝石卸下
Base.ECT_STONE_MIX = 15				-- 宝石合成
Base.ECT_MET_MIX = 16				-- 材料合成
Base.ECT_ITEM_SELL = 17				-- 道具寄售
Base.ECT_EQUIP_ITEM = 18			-- 装备装备
Base.ECT_LOGIN = 19					-- 连续登陆
Base.ECT_REACH_LV = 20				-- 达到特定等级
Base.ECT_GET_MONEY = 21				-- 获得钱
Base.ECT_COST_MONEY = 22			-- 花费钱
Base.ECT_CALL_CARD = 23             -- 召唤卡牌
Base.ECT_EQUIP_CARD = 24            -- 装备卡牌

Base.UF_NONE = 0
Base.UF_LV = 1
Base.UF_EXP = 2
Base.UF_RMB_MONEY = 3
Base.UF_STAGE = 4
Base.UF_ITEM = 5
Base.UF_GAME_MONEY = 6
Base.UF_EQUIP_WEAPON = 7
Base.UF_EQUIP_BODY = 8
Base.UF_EQUIP_HEAD = 9
Base.UF_EQUIP_FOOT = 10
Base.UF_EQUIP_HAND = 11
Base.UF_EQUIP_RING = 12
Base.UF_EQUIP_NECKLACE = 13
Base.UF_EQUIP_ACCESSORY = 14
Base.UF_EQUIP_CARD = 15
Base.UF_LAST_LOGIN_TIME = 16
Base.UF_LOGIN_TIME = 17
Base.UF_LOGOUT_TIME = 18
Base.UF_RANK = 19
Base.UF_ARENA_COUNT = 20
Base.UF_CHARGE_ARENA = 21
Base.UF_FIGHT_POINT = 22

Base.BUFF_TARGET_TYPE_SELF = 1
Base.BUFF_TARGET_TYPE_FRIEND = 2
Base.BUFF_TARGET_TYPE_ENEMY = 3
Base.BUFF_TARGET_TYPE_ALL = 4

Base.ID_TYPE_NONE = 0
Base.ID_TYPE_BUFFER = 1
Base.ID_TYPE_BULLET = 2

function Base.getIDType(id)
    if id >= 300000000 and id < 400000000 then
        return Base.ID_TYPE_BUFFER
    elseif id >= 400000000 and id < 500000000 then
        return Base.ID_TYPE_BULLET
    end
    return Base.ID_TYPE_NONE
end

Base.SOT_OPENCARD = 1				-- 翻卡
Base.SOT_COMPOSE = 2				-- 合成
Base.SOT_IMPROVE = 3				-- 改进
Base.SOT_INTENSIFY = 4				-- 强化
Base.SOT_GM = 5						-- GM操作
Base.SOT_MAINTASK = 6				-- 主线任务
Base.SOT_STAGE = 7					-- 关卡
Base.SOT_WEAREQUIP = 8				-- 穿装备
Base.SOT_CALLCARD = 9				-- 召唤卡牌
Base.SOT_ADDCARDEXP = 10			-- 卡牌经验
Base.SOT_ADDCARDSTAREXP = 11		-- 卡牌升星
Base.SOT_EQUIPCARD = 12				-- 装备卡牌
Base.SOT_ADDPLAYEREXP = 13			-- 增加经验
Base.SOT_SET = 14					-- 装备镶嵌
Base.SOT_DECOMPOSEQUIP = 15			-- 装备分解								
Base.SOT_UNSET = 16

Base.SOT_JOINRANK = 1000
Base.SOT_UPDATERANK = 1001
Base.SOT_QUERYRANK = 1002
Base.SOT_CHALLENGE = 1003

Base.SOT_UPDATEDAY = 2000

Base.SOT_SELLITEM = 3000
Base.SOT_BACKITEM = 3001
Base.SOT_BUYITEM = 3002
Base.SOT_GETTRADE = 3003
Base.SOT_GETPRICE = 3004

Base.BACK_OBJECT_LAYER = 1
Base.BACK_EFFECT_LAYER = 2
Base.BACK_MONSTER_EFFECT_LAYER = 3
Base.MONSTER_LAYER = 4
Base.BACK_PLAYER_EFFECT_LAYER = 5
Base.PLAYER_LAYER = 6
Base.FRONT_OBJECT_LAYER = 7
Base.FRONT_MONSTER_EFFECT_LAYER = 8
Base.FRONT_PLAYER_EFFECT_LAYER = 9
Base.FRONT_EFFECT_LAYER = 10
Base.FRONT_LAYER = 11
Base.NAME_LAYER = 12
Base.LAYER_NUMBER = 12

Base.LAYER_ORDERS = 1000

Base.NPC_TYPE_TREASURE = 1
Base.NPC_TYPE_MONSTER = 2
Base.NPC_TYPE_BOSS = 3
Base.NPC_TYPE_STATIC = 4
Base.NPC_TYPE_REFRESH = 5
Base.NPC_TYPE_ELIT = 6
Base.NPC_TYPE_BARRIER = 7

Base.ITEM_STATUS_NORMAL = 0
Base.ITEM_STATUS_SELLING = 1
Base.ITEM_STATUS_SELLED = 2

Base.OP_SUCCESS = 0

-- 主角头像图片
Base.PlayerHead = {
    "U_2672.png", 
    "U_2670.png", 
    "U_2671.png", 
    "U_2669.png"
}

Base.CARD_TYPE_IMG = {
    "U_9017.png",
    "U_9018.png",
    "U_9024.png",
    "U_9021.png",
    "U_9019.png",
    "U_9023.png",
    "U_9025.png",
    "U_9022.png",
    "U_9020.png"
}

Base.QUALITY_IMG = {
    "U_0080.png",
    "U_0082.png",
    "U_0083.png",
    "U_0077.png",
    "U_0079.png",
    "U_0081.png",
    "U_0076.png",
    "U_0078.png",
    "U_0053.png"
}

-- 碰撞方向
Base.eCollDirect = 
{
    "edc_none",
    "edc_left",
    "edc_right",
    "edc_up",
    "edc_bottom",
    "edc_max", 
}
Base.enumDirect = Base.CreatEnum(Base.eCollDirect)

-- 按键方向
Base.enum_JoystickDirect = 
{
    "ejd_nil",
    "ejd_up",
    "ejd_down",
    "ejd_left",
    "ejd_right",
    "ejd_uplift",
}


Base.roleState = 
{
	"eObj_State_Null",
	"eObj_State_Stand",
	"eObj_State_Attack",
	"eObj_State_Run",
	"eObj_State_Jump",
	"eObj_State_Fall",
	"eObj_State_Land",
	"eObj_State_Skill",
	"eObj_State_Dead",
	"eObj_State_Hurt",
	"eObj_State_HurtEx",
	"eObj_State_Down",
	"eObj_State_Up",
	"eObj_State_Rush",
	"eObj_State_Back",
	"eObj_State_Stun",
	"eObj_State_Ready_Climb",
	"eObj_State_Climb",
	"eObj_State_Climb_Stand",
	"eObj_State_Air",
	"eObj_State_Airhunt",
	"eObj_State_Ready",
	"eObj_State_Born",
}
Base.eRoleState = Base.CreatEnum(Base.roleState)

Base.aiState = 
    {
        "eAi_Null",
        "eAi_Stand1",
		"eAi_Wait",
        "eAi_Attack",
        "eAi_Skill1",
        "eAi_Skill2",
        "eAi_Skill3",
        "eAi_Skill4",
        "eAi_Skill5",
        "eAi_Card1",
        "eAi_Card2",
        "eAi_Card3",
        "eAi_Card4",
        "eAi_Move_Left",
        "eAi_Move_Right",
		"eAi_Move_Up",
		"eAi_born1",
		"eAi_Hide",
    }
Base.aiState = Base.CreatEnum(Base.aiState)

Base.aiRoleState = 
    {
        "eAi_Role_Init",
        "eAi_Role_Wait",
        "eAi_Role_Activity",
        "eAi_Role_Hide",
        "eAi_Role_Dying",
		"eAi_Role_Death",
    }
Base.aiRoleState = Base.CreatEnum(Base.aiRoleState)

Base.job = 
    {
        "eNull",
        "eWarrior",
		"eAssassin",
        "eMaster",
        "eWizard",
    }
Base.eJob = Base.CreatEnum(Base.job)

Base.Hurt = 
    {
        "e_Usually_Hurt",
        "e_Skill_Hurt",
        "e_Recovery_Hurt",
    }
Base.Hurt = Base.CreatEnum(Base.Hurt)

Base.NpcOpenUiType = 
    {
        "e_Open_Nill",
        "e_Open_Synthesis",
        "e_Open_Forging",
		"e_Open_Pvp",
		"e_Open_Achievement",
    }
Base.NpcOpenUiType = Base.CreatEnum(Base.NpcOpenUiType)

-- Base.HurtEffect = 
--     {
--         "e_Role_Hurt_Effect",
--         "e_Card_Hurt_Effect",
--     }
-- Base.HurtEffect = Base.CreatEnum(Base.HurtEffect)

return Base
