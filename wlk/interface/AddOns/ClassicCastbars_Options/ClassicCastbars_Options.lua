local L = LibStub("AceLocale-3.0"):GetLocale("ClassicCastbars")
local LSM = LibStub("LibSharedMedia-3.0")

local isClassicEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

local TEXT_POINTS = {
    ["CENTER"] = "CENTER",
    ["RIGHT"] = "RIGHT",
    ["LEFT"] = "LEFT",
}

local TEXT_OUTLINES = { -- font flags
    [""] = _G.DEFAULT,
    ["OUTLINE"] = "OUTLINE",
    ["THICK"] = "THICK",
    ["THICK,OUTLINE"] = "THICK OUTLINE",
    ["MONOCHROME"] = "MONOCHROME",
    ["MONOCHROME,OUTLINE"] = "MONOCHROME OUTLINE",
    ["MONOCHROME,THICK"] = "MONOCHROME THICK",
}

local CASTBAR_FRAME_STRATAS = {
    ["HIGH"] = "HIGH",
    ["MEDIUM"] = "MEDIUM",
    ["LOW"] = "LOW",
    ["BACKGROUND"] = "BACKGROUND",
}

local function GetLSMTable(lsmType)
    local tbl = CopyTable(LSM:HashTable(lsmType)) -- copy to prevent modifying LSM table

    -- Add custom media to LSM options that'll be used only in our addon.
    -- These are the default borders/fonts etc for ClassicCastbars
    if lsmType == "border" then
        tbl[_G.DEFAULT] = "Interface\\CastingBar\\UI-CastingBar-Border-Small"
    elseif lsmType == "font" then
        tbl[_G.DEFAULT] = _G.STANDARD_TEXT_FONT
    end

    return tbl
end

local function GetLSMNameByTexture(lsmType, texturePath)
    for name, texture in pairs(GetLSMTable(lsmType)) do
        if texture == texturePath then
            return name
        end
    end
end

local function CreateUnitTabGroup(unitID, localizedUnit, order)
    local function ModuleIsDisabled()
        return not ClassicCastbars.db[unitID].enabled
    end

    local function GetStatusColoredEnableText(unit)
        if ClassicCastbars.db[unit].enabled then
            return "|cFF20C000" .. L.TOGGLE_CASTBAR .. "|r"
        else
            return "|cFFFF0000" .. L.TOGGLE_CASTBAR .. "|r"
        end
    end

    -- https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables
    return {
        name = format("%s %s", L.CASTBAR, localizedUnit),
        order = order,
        type = "group",

        get = function(info) -- db.unit.key
            return ClassicCastbars.db[info[1]][info[3]]
        end,
        set = function(info, value) -- db.unit.key = value
            ClassicCastbars.db[info[1]][info[3]] = value
            ClassicCastbars_TestMode:OnOptionChanged(unitID)
        end,

        args = {
            general = {
                order = 1,
                name = L.GENERAL,
                type = "group",
                inline = false,

                args = {
                    -- WARN: Keys here has to match savedvariables/db key names,
                    -- or else you have to set a new 'get' and 'set' func to override the main ones above
                    enabled = {
                        order = 1,
                        name = GetStatusColoredEnableText(unitID),
                        desc = L.TOGGLE_CASTBAR_TOOLTIP,
                        width = "full", -- these have to be full to not truncate text in non-english locales
                        type = "toggle",
                        hidden = isClassicEra and unitID == "focus",
                        confirm = function()
                            return unitID == "player" and ClassicCastbars.db[unitID].enabled and L.REQUIRES_RESTART or false
                        end,
                        set = function(_, value)
                            ClassicCastbars.db[unitID].enabled = value
                            ClassicCastbars:ToggleUnitEvents(true)
                            ClassicCastbars:DisableBlizzardCastbar()

                            if unitID == "player" then
                                if value == false then
                                    return ReloadUI()
                                end
                                if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
                                    PlayerCastingBarFrame:SetLook("CLASSIC")
                                end
                                ClassicCastbars:SkinPlayerCastbar()
                            end
                        end,
                    },
                    showForFriendly = {
                        order = 2,
                        width = "full",
                        name = L.SHOW_FOR_FRIENDLY,
                        desc = "Note: does NOT work inside dungeons or raids due to Blizzard API limitations.",
                        type = "toggle",
                        disabled = ModuleIsDisabled,
                        hidden = unitID ~= "nameplate",
                    },
                    showForEnemy = {
                        order = 3,
                        width = "full",
                        name = L.SHOW_FOR_ENEMY,
                        type = "toggle",
                        disabled = ModuleIsDisabled,
                        hidden = unitID ~= "nameplate",
                    },
                    showForPets = {
                        order = 4,
                        width = "full",
                        name = L.SHOW_FOR_PETS,
                        type = "toggle",
                        disabled = ModuleIsDisabled,
                        hidden = unitID ~= "nameplate",
                    },
                    autoPosition = {
                        order = 5,
                        width = "full",
                        name = L.AUTO_POS_BAR,
                        desc = unitID ~= "player" and L.AUTO_POS_BAR_TOOLTIP or "",
                        type = "toggle",
                        hidden = unitID == "nameplate" or unitID == "party" or unitID == "arena",
                        disabled = ModuleIsDisabled,
                    },
                    showSpark = {
                        order = 6,
                        width = "full",
                        name = L.SHOW_SPARK,
                        type = "toggle",
                        disabled = ModuleIsDisabled,
                    },
                    showBorderShield = {
                        order = 7,
                        width = "full",
                        name = L.BORDERSHIELD,
                        desc = L.BORDERSHIELD_TOOLTIP,
                        type = "toggle",
                        disabled = ModuleIsDisabled,
                        hidden = unitID == "player",
                    },
                    ignoreParentAlpha = {
                        order = 8,
                        width = "full",
                        name = L.IGNORE_PARENT_ALPHA,
                        desc = L.IGNORE_PARENT_ALPHA_TOOLTIP,
                        type = "toggle",
                        disabled = ModuleIsDisabled,
                        hidden = unitID == "player",
                    },
                    ignoreParentScale = {
                        order = 9,
                        width = "full",
                        name = L.IGNORE_PARENT_SCALE,
                        desc = L.IGNORE_PARENT_SCALE_TOOLTIP,
                        type = "toggle",
                        disabled = ModuleIsDisabled,
                        hidden = unitID == "player",
                    },
                    posX = {
                        -- Position slider X for nameplate castbars only
                        order = 10,
                        name = L.POS_X,
                        desc = L.POSXY_TOOLTIP,
                        width = 2,
                        type = "range",
                        min = -999,
                        max = 999,
                        step = 1,
                        hidden = unitID ~= "nameplate",
                        get = function() return ClassicCastbars.db[unitID].position[2] end,
                        set = function(_, value)
                            ClassicCastbars.db[unitID].position[2] = value
                            local bar = ClassicCastbars:GetCastbarFrame("nameplate-testmode")
                            if bar then
                                bar:SetPoint("CENTER", bar.parent, value, ClassicCastbars.db[unitID].position[3])
                            end
                        end,
                    },
                    posY = {
                        -- Position slider Y for nameplate castbars only
                        order = 11,
                        name = L.POS_Y,
                        desc = L.POSXY_TOOLTIP,
                        width = 2,
                        type = "range",
                        min = -999,
                        max = 999,
                        step = 1,
                        hidden = unitID ~= "nameplate",
                        get = function()
                            return ClassicCastbars.db[unitID].position[3]
                        end,
                        set = function(_, value)
                            ClassicCastbars.db[unitID].position[3] = value
                            local bar = ClassicCastbars:GetCastbarFrame("nameplate-testmode")
                            if bar then
                                bar:SetPoint("CENTER", bar.parent, ClassicCastbars.db[unitID].position[2], value)
                            end
                        end,
                    },
                },
            },

            ----------------------------------------------------
            -- Castbar Size Options Tab
            ----------------------------------------------------
            sizing = {
                order = 2,
                name = L.CASTBAR_SIZING,
                type = "group",
                inline = false,
                disabled = ModuleIsDisabled,

                args = {
                    width = {
                        order = 1,
                        name = L.WIDTH,
                        width = 2,
                        type = "range",
                        min = 1,
                        max = 500,
                        step = 1,
                        bigStep = 10,
                    },
                    height = {
                        order = 2,
                        name = L.HEIGHT,
                        width = 2,
                        type = "range",
                        min = 1,
                        max = 200,
                        step = 1,
                        bigStep = 10,
                    },
                    borderPaddingHeight = {
                        order = 3,
                        name = L.BORDER_PADDING_HEIGHT,
                        width = 2,
                        type = "range",
                        min = 0.001,
                        max = 5.0,
                        step = 0.001,
                        bigStep = 0.001,
                    },
                    borderPaddingWidth = {
                        order = 4,
                        name = L.BORDER_PADDING_WIDTH,
                        width = 2,
                        type = "range",
                        min = 0.001,
                        max = 5.0,
                        step = 0.001,
                        bigStep = 0.001,
                    },
                },
            },

            ----------------------------------------------------
            -- Castbar Icon Options Tab
            ----------------------------------------------------
            castIcon = {
                order = 3,
                name = L.CASTBAR_ICON,
                type = "group",
                inline = false,
                disabled = ModuleIsDisabled,

                args = {
                    showIcon = {
                        order = 1,
                        width = "full",
                        name = L.ICON_SHOW,
                        type = "toggle",
                    },
                    hideIconBorder = {
                        order = 2,
                        width = "full",
                        name = L.ICON_HIDE_BORDER,
                        type = "toggle",
                    },
                    iconSize = {
                        order = 3,
                        name = L.ICON_SIZE,
                        desc = L.ICON_SIZE_TOOLTIP,
                        type = "range",
                        width = "double",
                        min = 1,
                        max = 100,
                        bigStep = 1,
                    },
                    iconPositionX = {
                        order = 4,
                        name = L.POS_X,
                        desc = L.POSXY_TOOLTIP,
                        type = "range",
                        min = -2000,
                        max = 2000,
                        bigStep = 5,
                    },
                    iconPositionY = {
                        order = 5,
                        name = L.POS_Y,
                        desc = L.POSXY_TOOLTIP,
                        type = "range",
                        min = -2000,
                        max = 2000,
                        bigStep = 5,
                    },
                },
            },

            ----------------------------------------------------
            -- Castbar Color Options Tab
            ----------------------------------------------------
            colors = {
                order = 4,
                name = L.CASTBAR_COLORS,
                type = "group",
                inline = false,
                disabled = ModuleIsDisabled,
                get = function(info)
                    return unpack(ClassicCastbars.db[info[1]][info[3]])
                end,
                set = function(info, r, g, b, a)
                    local cfg = ClassicCastbars.db[info[1]][info[3]]
                    cfg[1] = r -- overwrite values here instead of creating
                    cfg[2] = g -- a new table, so we can save memory. This function
                    cfg[3] = b -- is ran very frequently when picking colors
                    cfg[4] = a
                    ClassicCastbars_TestMode:OnOptionChanged(unitID)
                end,

                args = {
                    groupCastBarHeader = {
                        order = 0,
                        type = "header",
                        name = L.CASTBAR_COLORS,
                    },
                    borderColor = {
                        name = L.BORDER_COLOR,
                        order = 1,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                    textColor = {
                        name = L.TEXT_COLOR,
                        order = 2,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                    statusBackgroundColor = {
                        name = L.STATUS_BG_COLOR,
                        order = 3,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                    spacer = {
                        order = 5,
                        type = "description",
                        name = "\n\n\n",
                    },
                    groupCastFillHeader = {
                        order = 6,
                        type = "header",
                        name = L.CAST_FILL_HEADER,
                    },
                    statusColor = {
                        name = L.STATUS_COLOR,
                        order = 7,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                    statusColorSuccess = {
                        name = L.STATUS_SUCCESS_COLOR,
                        order = 8,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                    statusColorFailed = {
                        name = L.STATUS_FAILED_COLOR,
                        order = 9,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                    statusColorChannel = {
                        name = L.STATUS_CHANNEL_COLOR,
                        order = 10,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                    statusColorUninterruptible ={
                        name = L.STATUS_UNINTERRUPTIBLE_COLOR,
                        order = 11,
                        width = 1.2,
                        hasAlpha = true,
                        type = "color",
                    },
                },
            },

            ----------------------------------------------------
            -- Castbar Font Options Tab
            ----------------------------------------------------
            fonts = {
                order = 5,
                name = L.CASTBAR_FONTS,
                type = "group",
                inline = false,
                disabled = ModuleIsDisabled,

                args = {
                    castFontSize = {
                        order = 1,
                        name = L.FONT_SIZE,
                        desc = L.FONT_SIZE_TOOLTIP,
                        type = "range",
                        width = "double",
                        min = 1,
                        max = 50,
                        bigStep = 1,
                    },
                    textPositionX = {
                        order = 2,
                        name = L.POS_X,
                        desc = L.POSXY_TOOLTIP,
                        type = "range",
                        min = -2000,
                        max = 2000,
                        bigStep = 1,
                    },
                    textPositionY = {
                        order = 3,
                        name = L.POS_Y,
                        desc = L.POSXY_TOOLTIP,
                        type = "range",
                        min = -2000,
                        max = 2000,
                        bigStep = 1,
                    },
                    textPoint = {
                        order = 4,
                        name = L.TEXT_POINT,
                        type = "select",
                        values = TEXT_POINTS,
                    },
                    textOutline = {
                        order = 5,
                        name = L.TEXT_OUTLINE,
                        type = "select",
                        values = TEXT_OUTLINES,
                    },
                    header1 = {
                        order = 6,
                        type = "header",
                        name = "Timer Text",
                    },
                    showTimer = {
                        order = 7,
                        width = "full",
                        name = L.SHOW_TIMER,
                        desc = L.SHOW_TIMER_TOOLTIP,
                        type = "toggle",
                        disabled = ModuleIsDisabled,
                    },
                    showTotalTimer = {
                        order = 8,
                        width = "full",
                        name = L.SHOW_TOTAL_TIMER,
                        desc = L.SHOW_TOTAL_TIMER_TOOLTIP,
                        type = "toggle",
                        hidden = unitID ~= "player",
                        disabled = ClassicCastbars.db[unitID].showTimer == false or ModuleIsDisabled,
                    },
                    timerTextPositionX = {
                        order = 9,
                        name = L.POS_X,
                        desc = L.POSXY_TOOLTIP,
                        type = "range",
                        min = -2000,
                        max = 2000,
                        bigStep = 1,
                    },
                    timerTextPositionY = {
                        order = 10,
                        name = L.POS_Y,
                        desc = L.POSXY_TOOLTIP,
                        type = "range",
                        min = -2000,
                        max = 2000,
                        bigStep = 1,
                    },
                },
            },

            ----------------------------------------------------
            -- Castbar Textures Options Tab
            ----------------------------------------------------
            sharedMedia = {
                order = 6,
                name = L.CASTBAR_TEXTURE_FONT,
                type = "group",
                inline = false,
                disabled = ModuleIsDisabled,

                args = {
                    castFont = {
                        order = 1,
                        width = "double",
                        type = "select",
                        dialogControl = "LSM30_Font",
                        name = L.CAST_FONT,
                        desc = L.CAST_FONT_TOOLTIP,
                        values = GetLSMTable("font"),
                        get = function(info)
                            -- We store texture path instead of name in savedvariables so ClassicCastbars can still work
                            -- without LibSharedMedia or ClassicCastbars_Options loaded
                            return GetLSMNameByTexture("font", ClassicCastbars.db[info[1]][info[3]])
                        end,
                        set = function(info, value)
                            ClassicCastbars.db[info[1]][info[3]] = GetLSMTable("font")[value]
                            ClassicCastbars_TestMode:OnOptionChanged(unitID)
                        end,
                    },
                    spacer1 = {
                        order = 2,
                        type = "description",
                        name = "\n\n",
                    },
                    castStatusBar = {
                        order = 3,
                        width = "double",
                        type = "select",
                        dialogControl = "LSM30_Statusbar",
                        name = L.CAST_STATUSBAR,
                        desc = L.CAST_STATUSBAR_TOOLTIP,
                        values = GetLSMTable("statusbar"),
                        get = function(info)
                            return GetLSMNameByTexture("statusbar", ClassicCastbars.db[info[1]][info[3]])
                        end,
                        set = function(info, value)
                            ClassicCastbars.db[info[1]][info[3]] = LSM:HashTable("statusbar")[value]
                            ClassicCastbars_TestMode:OnOptionChanged(unitID)
                        end,
                    },
                    spacer2 = {
                        order = 4,
                        type = "description",
                        name = "\n\n",
                    },
                    castBorder = {
                        order = 5,
                        width = "double",
                        type = "select",
                        dialogControl = "LSM30_Border",
                        name = L.CAST_BORDER,
                        desc = L.CAST_BORDER_TOOLTIP,
                        values = GetLSMTable("border"),
                        get = function(info)
                            return GetLSMNameByTexture("border", ClassicCastbars.db[info[1]][info[3]])
                        end,
                        set = function(info, value)
                            ClassicCastbars.db[info[1]][info[3]] = GetLSMTable("border")[value]
                            if ClassicCastbars.db[info[1]].showBorderShield then
                                print("ClassicCastbars: " .. L.CAST_BORDER_SHIELD_NOTICE) --luacheck: ignore
                            end
                            ClassicCastbars_TestMode:OnOptionChanged(unitID)
                        end,
                    },
                    edgeSizeLSM = {
                        order = 6,
                        name = L.EDGE_SIZE_LSM,
                        type = "range",
                        width = "double",
                        min = 3,
                        max = 32,
                        bigStep = 1,
                        disabled = function()
                            return ClassicCastbars.db[unitID].castBorder == "Interface\\CastingBar\\UI-CastingBar-Border-Small"
                        end,
                    },
                    spacer3 = {
                        order = 7,
                        type = "description",
                        name = "\n\n",
                    },
                    frameLevel = {
                        order = 8,
                        name = L.FRAME_LEVEL,
                        desc = L.FRAME_LEVEL_DESC,
                        type = "range",
                        min = 0,
                        max = 99,
                        bigStep = 5,
                    },
                    frameStrata = {
                        order = 9,
                        name = L.FRAME_STRATA,
                        desc = L.FRAME_STRATA_DESC,
                        type = "select",
                        values = CASTBAR_FRAME_STRATAS,
                    },
                },
           },

            ----------------------------------------------------
            -- Test Button
            ----------------------------------------------------
           testing = {
                order = -1,
                name = "",
                inline = true,
                type = "group",

                args = {
                    test = {
                        order = 1,
                        width = 1.4,
                        name = format("%s %s", L.TEST, localizedUnit),
                        desc = string.match(L.BORDERSHIELD_TOOLTIP, "|cffffff00(.*)|r"),
                        type = "execute",
                        disabled = function() return not ClassicCastbars.db[unitID].enabled end,
                        func = function() ClassicCastbars_TestMode:ToggleCastbarMovable(unitID) end,
                    },
                    spacer = {
                        order = 2,
                        name = "\n",
                        type = "description",
                    },
                },
            },
        },
    }
end

local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata

local function GetOptionsTable()
    return { -- only create table on demand
        type = "group",
        childGroups = "tab",
        name = "ClassicCastbars " .. GetAddOnMetadata("ClassicCastbars", "version"),

        args = {
            target = CreateUnitTabGroup("target", _G.TARGET, 1),
            nameplate = CreateUnitTabGroup("nameplate", _G.UNIT_NAMEPLATES, 2),
            party = CreateUnitTabGroup("party", _G.PARTY, 3),
            player = CreateUnitTabGroup("player", _G.PLAYER, 4),
            focus = not isClassicEra and CreateUnitTabGroup("focus", _G.FOCUS, 5) or nil,
            arena = not isClassicEra and CreateUnitTabGroup("arena", _G.ARENA, 6) or nil,

            -- Reset Button
            resetAllSettings = {
                order = 7,
                name = L.RESET_ALL,
                type = "execute",
                confirm = function()
                    return _G.CONFIRM_RESET_SETTINGS
                end,
                func = function()
                    local shouldReloadUI = ClassicCastbars.db.player.enabled
                    -- Reset savedvariables to default
                    ClassicCastbarsCharDB = {}
                    ClassicCastbarsDB = CopyTable(ClassicCastbars.defaultConfig)
                    ClassicCastbars.db = ClassicCastbarsDB -- update pointer

                    ClassicCastbars_TestMode:OnOptionChanged("target")
                    ClassicCastbars_TestMode:OnOptionChanged("nameplate")
                    ClassicCastbars_TestMode:OnOptionChanged("party")
                    ClassicCastbars_TestMode:OnOptionChanged("player")
                    ClassicCastbars_TestMode:OnOptionChanged("focus")
                    ClassicCastbars_TestMode:OnOptionChanged("arena")

                    if shouldReloadUI then
                        ReloadUI()
                    end
                end,
            },

            -- Character specific savedvariables Checkbox
            usePerCharacterSettings = {
                order = 8,
                width = 1.3,
                type = "toggle",
                name = L.PER_CHARACTER,
                desc = L.PER_CHARACTER_TOOLTIP,
                confirm = true,
                confirmText = _G.VIDEO_OPTIONS_NEED_CLIENTRESTART,
                get = function()
                    return ClassicCastbarsCharDB and ClassicCastbarsCharDB.usePerCharacterSettings
                end,
                set = function(_, value)
                    if not next(ClassicCastbarsCharDB or {}) then
                        ClassicCastbarsCharDB = CopyTable(ClassicCastbarsDB)
                    end
                    ClassicCastbarsCharDB.usePerCharacterSettings = value
                    ReloadUI()
                end,
            },
        },
    }
end

-- Initialize option panel
LibStub("AceConfig-3.0"):RegisterOptionsTable("ClassicCastbars", GetOptionsTable)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ClassicCastbars")
